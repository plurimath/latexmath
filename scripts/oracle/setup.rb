# frozen_string_literal: true

# Prepare the isolated dependency environment for a pinned Plurimath checkout.
#
#   ruby scripts/oracle/setup.rb --oracle PATH
#
# PATH must be a clean git checkout of the commit named in pins.yml. The
# script copies oracle.gemfile and oracle.gemfile.lock into
# PATH/.latexmath-oracle/ and installs the locked gems into
# PATH/.latexmath-oracle/vendor/bundle (frozen; the lock is never re-resolved).
# Add /.latexmath-oracle/ to PATH/.git/info/exclude so the checkout stays clean.

require "fileutils"
require "optparse"
require_relative "lib/latexmath_oracle/oracle_env"

oracle = nil
OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/oracle/setup.rb --oracle PATH"
  opts.on("--oracle PATH", "Pinned Plurimath checkout") { |value| oracle = value }
end.parse!
abort "--oracle is required" unless oracle

env = LatexmathOracle::OracleEnv.new(oracle)
env.verify_checkout!
FileUtils.mkdir_p(env.dir)
FileUtils.cp(LatexmathOracle::OracleEnv::GEMFILE, env.gemfile)
FileUtils.cp(LatexmathOracle::OracleEnv::LOCKFILE, env.lockfile)

bundle_env = { "BUNDLE_GEMFILE" => env.gemfile }
install = lambda do
  system(bundle_env, "bundle", "config", "set", "--local", "path", "vendor/bundle", exception: true)
  system(bundle_env, "bundle", "config", "set", "--local", "frozen", "true", exception: true)
  system(bundle_env, "bundle", "install", exception: true)
end
defined?(Bundler) ? Bundler.with_unbundled_env(&install) : install.call
env.verify_lock!
puts "oracle environment ready: #{env.dir}"
