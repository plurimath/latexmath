# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

# Every spec. Without LATEXMATH_REQUIRE_NATIVE=1 the native-engine examples
# skip where Parsanol's native extension is not available; the oracle
# parity spec runs only with a captured report (see the replay workflow).
RSpec::Core::RakeTask.new(:spec)

task default: :spec
