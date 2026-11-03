# frozen_string_literal: true

require "rbconfig"
require "tmpdir"
require_relative "../../scripts/oracle/lib/latexmath_oracle/harness"

RSpec.describe "oracle capture harness" do
  let(:fake_worker) { File.expand_path("support/fake_worker.rb", __dir__) }

  let(:tmp) { Dir.mktmpdir("latexmath-oracle-spec") }
  let(:log) { File.join(tmp, "worker.log") }
  let(:identity) { { "plurimath_commit" => "fake", "worker_sha256" => "fake" } }

  after { FileUtils.remove_entry(tmp) }

  def inventory(rows)
    LatexmathOracle::Inventory.new("inline.yaml", "0" * 64,
                                   rows.map { |row| { "input" => "x" }.merge(row) })
  end

  def runner(rows, timeout: 10, ids: nil, checkpoint: nil)
    LatexmathOracle::Runner.new(
      inventory: inventory(rows), ids: ids,
      command: [RbConfig.ruby, fake_worker],
      env: { "FAKE_WORKER_LOG" => log },
      timeout: timeout, identity: identity, checkpoint: checkpoint, log: nil
    )
  end

  def capture(behaviour, **options)
    report = runner([{ "id" => "row", "behaviour" => behaviour }.merge(options.delete(:row) || {})],
                    **options).run
    report["rows"].first
  end

  def invocations
    File.exist?(log) ? File.readlines(log, chomp: true) : []
  end

  describe "classification" do
    it "records a successful reply as succeeded" do
      row = capture("success")
      expect(row["status"]).to eq("succeeded")
      expect(row["capture"]).to include("status" => "ok")
      expect(row["exit"]).to eq("code" => 0, "signal" => nil)
    end

    it "records a parse refusal as refused data, not a failure" do
      row = capture("refusal")
      expect(row["status"]).to eq("refused")
      expect(row["capture"]).to include("status" => "refused")
    end

    it "times out only after the real deadline passes" do
      row = capture("hang", timeout: 1.5)
      expect(row["status"]).to eq("timed_out")
      expect(row["duration_s"]).to be >= 1.5
      expect(row["duration_s"]).to be < 10
      expect(row["exit"]["signal"]).not_to be_nil
    end

    it "does not treat stdout EOF before process exit as a timeout" do
      row = capture("eof_then_exit", timeout: 8, row: { "linger" => 1.5 })
      expect(row["status"]).to eq("succeeded")
      expect(row["duration_s"]).to be >= 1.5
    end

    it "keeps waiting after EOF and times out a child that never exits" do
      row = capture("eof_then_hang", timeout: 1.5)
      expect(row["status"]).to eq("timed_out")
      expect(row["duration_s"]).to be >= 1.5
    end

    it "records a non-zero exit as crashed even when a reply was written" do
      row = capture("exit_nonzero")
      expect(row["status"]).to eq("crashed")
      expect(row["reason"]).to eq("nonzero_exit")
      expect(row["exit"]["code"]).to eq(3)
      expect(row["stderr_tail"]).to include("failing on purpose")
    end

    it "records an uncaught exception as crashed" do
      row = capture("raise")
      expect(row["status"]).to eq("crashed")
      expect(row["exit"]["code"]).to eq(1)
    end

    it "records death by signal as crashed, not timed out" do
      row = capture("signal")
      expect(row["status"]).to eq("crashed")
      expect(row["exit"]["signal"]).to eq(Signal.list.fetch("KILL"))
    end

    it "records unreadable output as crashed" do
      expect(capture("garbage")).to include("status" => "crashed", "reason" => "invalid_output")
      expect(capture("unknown_status")).to include("status" => "crashed", "reason" => "invalid_output")
    end
  end

  describe "report" do
    let(:rows) do
      [
        { "id" => "a", "behaviour" => "success" },
        { "id" => "b", "behaviour" => "refusal" },
        { "id" => "c", "behaviour" => "hang" },
        { "id" => "d", "behaviour" => "raise" },
      ]
    end

    it "reconciles counts against the selected inventory" do
      report = runner(rows, timeout: 1.5).run
      expect(report["counts"]).to include(
        "expected" => 4, "attempted_this_run" => 4, "succeeded" => 1,
        "refused" => 1, "timed_out" => 1, "crashed" => 1,
        "missing" => 0, "duplicate" => 0
      )
      expect(report["reconciled"]).to be(true)
      expect(report["complete"]).to be(false)
      expect(report["rows"].map { |row| row["id"] }).to eq(%w[a b c d])
    end

    it "is complete when every selected row succeeded or was refused" do
      report = runner(rows, ids: %w[b a]).run
      expect(report["selected_ids"]).to eq(%w[a b])
      expect(report["counts"]).to include("expected" => 2, "succeeded" => 1, "refused" => 1)
      expect(report["complete"]).to be(true)
      expect(invocations).to eq(%w[a b])
    end

    it "rejects unknown and duplicate requested ids" do
      expect { runner(rows, ids: %w[a zz]) }.to raise_error(LatexmathOracle::Error, /unknown ids: zz/)
      expect { runner(rows, ids: %w[a a]) }.to raise_error(LatexmathOracle::Error, /duplicate ids/)
    end

    it "rejects an inventory with duplicate row ids" do
      expect { inventory([{ "id" => "a" }, { "id" => "a" }]) }
        .to raise_error(LatexmathOracle::Error, /duplicate row ids: a/)
    end
  end

  describe "checkpoint resume" do
    let(:checkpoint) { File.join(tmp, "capture.jsonl") }
    let(:rows) do
      [
        { "id" => "a", "behaviour" => "success" },
        { "id" => "b", "behaviour" => "refusal" },
        { "id" => "c", "behaviour" => "success" },
      ]
    end

    it "skips rows already completed and drops an interrupted trailing line" do
      first = runner(rows, ids: %w[a], checkpoint: checkpoint)
      fingerprint = runner(rows, checkpoint: checkpoint).fingerprint
      expect(first.fingerprint).not_to eq(fingerprint)

      # Simulate an interrupted run of the full selection: header, row a
      # completed, row b half written when the process died.
      File.write(checkpoint, [
        JSON.generate("kind" => "header", "fingerprint" => fingerprint),
        JSON.generate("kind" => "row", "id" => "a", "status" => "succeeded", "capture" => {}),
        '{"kind":"row","id":"b","sta',
      ].join("\n"))

      report = runner(rows, checkpoint: checkpoint).run
      expect(invocations).to eq(%w[b c])
      expect(report["counts"]).to include("expected" => 3, "attempted_this_run" => 2,
                                          "resumed_from_checkpoint" => 1, "succeeded" => 2,
                                          "refused" => 1, "missing" => 0)
      expect(report["complete"]).to be(true)

      lines = File.readlines(checkpoint)
      expect(lines.last).to end_with("\n")
      expect(lines.map { |line| JSON.parse(line)["id"] }).to eq([nil, "a", "b", "c"])
    end

    it "retries rows that timed out or crashed before" do
      flaky = [{ "id" => "a", "behaviour" => "success" }, { "id" => "b", "behaviour" => "hang" }]
      first = runner(flaky, timeout: 1.5, checkpoint: checkpoint).run
      expect(first["counts"]).to include("succeeded" => 1, "timed_out" => 1)

      fixed = [{ "id" => "a", "behaviour" => "success" }, { "id" => "b", "behaviour" => "success" }]
      second = runner(fixed, timeout: 1.5, checkpoint: checkpoint).run
      expect(invocations).to eq(%w[a b b])
      expect(second["counts"]).to include("succeeded" => 2, "timed_out" => 0,
                                          "resumed_from_checkpoint" => 1)
      expect(second["complete"]).to be(true)
    end

    it "refuses to resume a checkpoint from a different capture" do
      File.write(checkpoint, "#{JSON.generate('kind' => 'header', 'fingerprint' => 'other')}\n")
      expect { runner(rows, checkpoint: checkpoint).run }
        .to raise_error(LatexmathOracle::Error, /fingerprint mismatch/)
      expect(invocations).to be_empty
    end
  end
end
