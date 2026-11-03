# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "yaml"

module LatexmathOracle
  class Error < StandardError; end

  # Rows to capture, read from a YAML inventory such as corpora/oracle/smoke.yaml.
  class Inventory
    attr_reader :path, :sha256, :rows

    def self.load(path)
      bytes = File.binread(path)
      data = YAML.safe_load(bytes)
      raise Error, "#{path}: expected a mapping with rows" unless data.is_a?(Hash) && data["rows"].is_a?(Array)

      new(path, Digest::SHA256.hexdigest(bytes), data["rows"])
    end

    def initialize(path, sha256, rows)
      @path = path
      @sha256 = sha256
      @rows = rows
      validate!
    end

    def ids
      rows.map { |row| row["id"] }
    end

    # Rows for +ids+ in inventory order; all rows when +ids+ is nil.
    def select(ids)
      return rows if ids.nil?

      duplicates = ids.tally.select { |_, n| n > 1 }.keys
      raise Error, "duplicate ids requested: #{duplicates.join(', ')}" unless duplicates.empty?

      unknown = ids - self.ids
      raise Error, "unknown ids: #{unknown.join(', ')}" unless unknown.empty?

      rows.select { |row| ids.include?(row["id"]) }
    end

    private

    def validate!
      rows.each_with_index do |row, index|
        unless row.is_a?(Hash) && row["id"].is_a?(String) && row["input"].is_a?(String)
          raise Error, "#{path}: row #{index} needs string id and input"
        end
      end
      duplicates = ids.tally.select { |_, n| n > 1 }.keys
      raise Error, "#{path}: duplicate row ids: #{duplicates.join(', ')}" unless duplicates.empty?
    end
  end

  # Runs one child process per row with a real monotonic deadline.
  #
  # End of file on the child's stdout is not completion: the child may still
  # be running. The supervisor keeps polling the process status until the
  # child exits or the deadline passes. Only a passed deadline with a live
  # child is a timeout.
  class Supervisor
    Result = Struct.new(:stdout, :stderr, :status, :timed_out, :duration, keyword_init: true)

    POLL = 0.05
    KILL_GRACE = 1.0
    STDERR_TAIL = 8192

    def initialize(command:, env: {}, timeout:)
      @command = command
      @env = env
      @timeout = timeout
    end

    def run(input)
      started = now
      deadline = started + @timeout
      in_r, in_w = IO.pipe
      out_r, out_w = IO.pipe
      err_r, err_w = IO.pipe
      pid = spawn_child(in_r, out_w, err_w)
      [in_r, out_w, err_w].each(&:close)
      writer = feed(in_w, input)

      stdout = +"".b
      stderr = +"".b
      open = { out_r => stdout, err_r => stderr }
      status = nil
      timed_out = false

      loop do
        status ||= reap(pid)
        break if status && open.empty?

        remaining = deadline - now
        if remaining <= 0
          if status.nil?
            timed_out = true
            status = kill(pid)
          end
          break
        end

        if open.empty?
          sleep([POLL, remaining].min)
          next
        end

        ready, = IO.select(open.keys, nil, nil, [POLL, remaining].min)
        (ready || []).each do |io|
          open[io] << io.read_nonblock(65_536)
        rescue IO::WaitReadable
          next
        rescue EOFError
          open.delete(io)
        end
      end

      Result.new(stdout: stdout, stderr: tail(stderr), status: status,
                 timed_out: timed_out, duration: now - started)
    ensure
      writer&.kill
      [in_w, out_r, err_r].each { |io| io&.close unless io&.closed? }
      cleanup_group(pid) if pid
    end

    private

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def spawn_child(stdin, stdout, stderr)
      Process.spawn(@env, *@command, in: stdin, out: stdout, err: stderr,
                                     pgroup: true)
    end

    def feed(io, input)
      Thread.new do
        io.write(input)
      rescue Errno::EPIPE, IOError
        nil
      ensure
        io.close unless io.closed?
      end
    end

    def reap(pid)
      _, status = Process.waitpid2(pid, Process::WNOHANG)
      status
    rescue Errno::ECHILD
      nil
    end

    def kill(pid)
      signal_group(pid, "TERM")
      limit = now + KILL_GRACE
      while now < limit
        status = reap(pid)
        return status if status

        sleep POLL
      end
      signal_group(pid, "KILL")
      _, status = Process.waitpid2(pid)
      status
    end

    # Remove anything the child left behind in its process group.
    def cleanup_group(pid)
      signal_group(pid, "KILL")
      Process.waitpid2(pid, Process::WNOHANG)
    rescue Errno::ECHILD
      nil
    end

    def signal_group(pid, signal)
      Process.kill(signal, -pid)
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end

    def tail(bytes)
      text = bytes.byteslice([bytes.bytesize - STDERR_TAIL, 0].max, STDERR_TAIL)
      text.force_encoding(Encoding::UTF_8).scrub
    end
  end

  # Every JSON document the harness writes or reads (requests, replies,
  # checkpoint lines, reports) is generated and parsed with
  # max_nesting: false: the raw tree and formula of nested input go deeper
  # than JSON's default limit of 100.

  # Append-only JSON Lines record of completed rows, so an interrupted capture
  # can resume. Every row is written as one line and fsynced before the next
  # row starts. A trailing line without a newline is an interrupted write and
  # is dropped on open.
  class Checkpoint
    TERMINAL = %w[succeeded refused].freeze

    attr_reader :rows

    def initialize(path, fingerprint)
      @path = path
      @fingerprint = fingerprint
      @rows = {}
      load_existing
      @file = File.open(path, "a")
      write_line("kind" => "header", "fingerprint" => fingerprint) if @fresh
    end

    # Rows that do not need another attempt.
    def done?(id)
      row = rows[id]
      row && TERMINAL.include?(row["status"])
    end

    def record(row)
      rows[row["id"]] = row
      write_line({ "kind" => "row" }.merge(row))
    end

    def close
      @file&.close
    end

    private

    def load_existing
      @fresh = !File.exist?(@path) || File.size(@path).zero?
      return if @fresh

      bytes = File.binread(@path)
      complete = bytes.end_with?("\n") ? bytes : bytes[0, (bytes.rindex("\n") || -1) + 1]
      File.truncate(@path, complete.bytesize) if complete.bytesize != bytes.bytesize

      lines = complete.each_line.map { |line| JSON.parse(line, max_nesting: false) }
      header = lines.shift
      if header.nil?
        @fresh = true
        return
      end
      unless header["kind"] == "header" && header["fingerprint"] == @fingerprint
        raise Error, "checkpoint #{@path} belongs to a different capture (fingerprint mismatch)"
      end

      lines.each { |line| rows[line["id"]] = line.reject { |key, _| key == "kind" } }
    end

    def write_line(data)
      @file.write("#{JSON.generate(data, max_nesting: false)}\n")
      @file.flush
      @file.fsync
    end
  end

  # Captures every selected row and builds the report.
  class Runner
    SCHEMA = "latexmath-oracle-capture/1"
    STATUSES = %w[succeeded refused timed_out crashed].freeze

    # +identity+ describes the oracle (commit, lock, worker checksum); it is
    # copied into the report and into the checkpoint fingerprint.
    def initialize(inventory:, ids:, command:, env: {}, timeout:, identity:,
                   checkpoint: nil, log: $stderr)
      @inventory = inventory
      @rows = inventory.select(ids)
      @selected_ids = @rows.map { |row| row["id"] }
      @command = command
      @env = env
      @timeout = timeout
      @identity = identity
      @checkpoint_path = checkpoint
      @log = log
    end

    def fingerprint
      Digest::SHA256.hexdigest(JSON.generate(
                                 "schema" => SCHEMA,
                                 "identity" => @identity,
                                 "inventory_sha256" => @inventory.sha256,
                                 "selected_ids" => @selected_ids,
                               ))
    end

    def run
      checkpoint = @checkpoint_path && Checkpoint.new(@checkpoint_path, fingerprint)
      results = {}
      attempted = Hash.new(0)
      resumed = []
      supervisor = Supervisor.new(command: @command, env: @env, timeout: @timeout)

      @rows.each do |row|
        id = row["id"]
        if checkpoint&.done?(id)
          results[id] = checkpoint.rows[id]
          resumed << id
          @log&.puts("#{id}: #{results[id]['status']} (from checkpoint)")
          next
        end

        attempted[id] += 1
        result = classify(row, supervisor.run(JSON.generate({ "row" => row }, max_nesting: false)))
        results[id] = result
        checkpoint&.record(result)
        @log&.puts("#{id}: #{result['status']} (#{result['duration_s']}s)")
      end

      report(results, attempted, resumed)
    ensure
      checkpoint&.close
    end

    private

    def classify(row, outcome)
      base = { "id" => row["id"], "duration_s" => outcome.duration.round(3),
               "exit" => exit_info(outcome.status) }
      return base.merge("status" => "timed_out", "stderr_tail" => outcome.stderr) if outcome.timed_out

      unless outcome.status&.success?
        return base.merge("status" => "crashed", "reason" => "nonzero_exit",
                          "stderr_tail" => outcome.stderr)
      end

      payload = parse_payload(outcome.stdout)
      case payload && payload["status"]
      when "ok" then base.merge("status" => "succeeded", "capture" => payload)
      when "refused" then base.merge("status" => "refused", "capture" => payload)
      else
        base.merge("status" => "crashed", "reason" => "invalid_output",
                   "stderr_tail" => outcome.stderr)
      end
    end

    def parse_payload(bytes)
      text = bytes.dup.force_encoding(Encoding::UTF_8)
      return nil unless text.valid_encoding?

      data = JSON.parse(text, max_nesting: false)
      data.is_a?(Hash) ? data : nil
    rescue JSON::ParserError
      nil
    end

    def exit_info(status)
      return nil if status.nil?

      { "code" => status.exitstatus, "signal" => status.termsig }
    end

    def report(results, attempted, resumed)
      rows = @selected_ids.filter_map { |id| results[id] }
      counts = STATUSES.to_h { |status| [status, rows.count { |row| row["status"] == status }] }
      missing = @selected_ids - results.keys
      duplicates = rows.map { |row| row["id"] }.tally.select { |_, n| n > 1 }.keys
      reconciled = counts.values.sum == @selected_ids.size && missing.empty? && duplicates.empty?
      complete = reconciled && counts["timed_out"].zero? && counts["crashed"].zero?

      {
        "schema" => SCHEMA,
        "oracle" => @identity,
        "inventory" => {
          "path" => @inventory.path,
          "sha256" => @inventory.sha256,
          "rows" => @inventory.rows.size,
        },
        "selected_ids" => @selected_ids,
        "settings" => { "timeout_s" => @timeout },
        "counts" => {
          "expected" => @selected_ids.size,
          "attempted_this_run" => attempted.values.sum,
          "resumed_from_checkpoint" => resumed.size,
        }.merge(counts).merge(
          "missing" => missing.size,
          "duplicate" => duplicates.size,
        ),
        "missing_ids" => missing,
        "duplicate_ids" => duplicates,
        "reconciled" => reconciled,
        "complete" => complete,
        "rows" => rows,
      }
    end
  end

  module_function

  # Write +data+ as pretty JSON through a temporary file and rename, so a
  # reader never sees a half-written report.
  def write_json_atomically(path, data)
    FileUtils.mkdir_p(File.dirname(path))
    tmp = "#{path}.tmp-#{Process.pid}"
    File.write(tmp, "#{JSON.pretty_generate(data, max_nesting: false)}\n")
    File.rename(tmp, path)
  end
end
