# frozen_string_literal: true

# Stand-in for scripts/oracle/latex_worker.rb in the harness specs. The row's
# "behaviour" field picks how the child ends, so each supervisor and
# classification path can be driven without loading Plurimath.

require "json"

request = JSON.parse($stdin.read)
row = request.fetch("row")
if (log = ENV["FAKE_WORKER_LOG"])
  File.open(log, "a") { |f| f.puts(row["id"]) }
end

reply = ->(status) { JSON.generate("id" => row["id"], "status" => status) }

case row.fetch("behaviour")
when "success"
  $stdout.write(reply.call("ok"))
when "refusal"
  $stdout.write(reply.call("refused"))
when "hang"
  sleep 120
when "eof_then_exit"
  # Reply, close stdout, keep running a while, then exit cleanly. EOF here
  # is not completion and must not be reported as a timeout.
  $stdout.write(reply.call("ok"))
  $stdout.close
  sleep Float(row.fetch("linger", 1.5))
when "eof_then_hang"
  $stdout.close
  sleep 120
when "exit_nonzero"
  $stdout.write(reply.call("ok"))
  warn "fake worker failing on purpose"
  exit 3
when "raise"
  raise "fake worker exception"
when "signal"
  Process.kill("KILL", Process.pid)
when "garbage"
  $stdout.write("not json")
when "unknown_status"
  $stdout.write(reply.call("maybe"))
else
  abort "unknown behaviour #{row['behaviour']}"
end
