# frozen_string_literal: true

# Capture legacy Plurimath LaTeX behaviour for inventory rows, one fresh
# child process per row.
#
#   bundle exec ruby scripts/oracle/capture.rb --oracle PATH --report FILE \
#     [--inputs corpora/oracle/smoke.yaml] [--ids a,b] [--timeout 300] \
#     [--checkpoint FILE]
#
# Run scripts/oracle/setup.rb --oracle PATH first. With --checkpoint, rows
# already succeeded or refused in that file are not run again; timed-out and
# crashed rows are retried.
#
# Exit status: 0 when every selected row succeeded or was refused and the
# counts reconcile; 1 when any row timed out, crashed or is missing; 2 on a
# usage, pin or lock error.

require "optparse"
require_relative "lib/latexmath_oracle/harness"
require_relative "lib/latexmath_oracle/oracle_env"

options = {
  inputs: File.expand_path("../../corpora/oracle/smoke.yaml", __dir__),
  timeout: 300.0,
}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/oracle/capture.rb --oracle PATH --report FILE [options]"
  opts.on("--oracle PATH", "Pinned Plurimath checkout prepared by setup.rb") { |v| options[:oracle] = v }
  opts.on("--inputs FILE", "Inventory YAML (default corpora/oracle/smoke.yaml)") { |v| options[:inputs] = v }
  opts.on("--ids LIST", Array, "Comma-separated row ids (default: all rows)") { |v| options[:ids] = v }
  opts.on("--report FILE", "Report JSON to write") { |v| options[:report] = v }
  opts.on("--checkpoint FILE", "JSON Lines checkpoint for resume") { |v| options[:checkpoint] = v }
  opts.on("--timeout SECONDS", Float, "Per-row deadline (default 300)") { |v| options[:timeout] = v }
end.parse!

begin
  raise LatexmathOracle::Error, "--oracle is required" unless options[:oracle]
  raise LatexmathOracle::Error, "--report is required" unless options[:report]

  env = LatexmathOracle::OracleEnv.new(options[:oracle])
  env.verify!
  inventory = LatexmathOracle::Inventory.load(options[:inputs])
  root = File.expand_path("../..", __dir__)
  inventory_path = File.expand_path(options[:inputs])
  inventory_path = inventory_path.delete_prefix("#{root}/") if inventory_path.start_with?("#{root}/")
  inventory = LatexmathOracle::Inventory.new(inventory_path, inventory.sha256, inventory.rows)

  runner = LatexmathOracle::Runner.new(
    inventory: inventory,
    ids: options[:ids],
    command: env.command,
    env: env.child_env,
    timeout: options[:timeout],
    identity: env.identity,
    checkpoint: options[:checkpoint],
  )
  report = runner.run
rescue LatexmathOracle::Error => e
  warn "capture: #{e.message}"
  exit 2
end

LatexmathOracle.write_json_atomically(options[:report], report)
counts = report["counts"]
warn format("capture: expected=%<expected>d succeeded=%<succeeded>d refused=%<refused>d " \
            "timed_out=%<timed_out>d crashed=%<crashed>d missing=%<missing>d complete=%<complete>s",
            counts.transform_keys(&:to_sym).merge(complete: report["complete"]))
exit(report["complete"] ? 0 : 1)
