# frozen_string_literal: true

require "digest"
require "open3"
require "rbconfig"
require "yaml"
require_relative "harness"

module LatexmathOracle
  # The pinned Plurimath checkout plus its isolated bundle.
  class OracleEnv
    ROOT = File.expand_path("../..", __dir__)
    GEMFILE = File.join(ROOT, "oracle.gemfile")
    LOCKFILE = File.join(ROOT, "oracle.gemfile.lock")
    WORKER = File.join(ROOT, "latex_worker.rb")
    PINS = File.join(ROOT, "pins.yml")
    WORKER_SOURCES = [
      WORKER,
      File.join(ROOT, "lib/latexmath_oracle/tagged.rb"),
    ].freeze

    attr_reader :checkout

    # +pins+ and +lock+ default to the committed pins.yml and
    # oracle.gemfile.lock; the specs pass their own.
    def initialize(checkout, pins: nil, lock: LOCKFILE)
      @checkout = File.expand_path(checkout)
      @pins = pins
      @lock = lock
    end

    def pins
      @pins ||= YAML.safe_load(File.read(PINS))
    end

    def dir
      File.join(checkout, ".latexmath-oracle")
    end

    def gemfile
      File.join(dir, "Gemfile")
    end

    def lockfile
      File.join(dir, "Gemfile.lock")
    end

    def commit
      git("rev-parse", "HEAD")
    end

    def verify_checkout!
      expected = pins.fetch("plurimath").fetch("commit")
      actual = commit
      raise Error, "oracle checkout is at #{actual}, pins.yml requires #{expected}" unless actual == expected

      dirty = git("status", "--porcelain", "--untracked-files=all")
      raise Error, "oracle checkout has local changes:\n#{dirty}" unless dirty.empty?

      pins.fetch("plurimath").fetch("latex_sources").each do |path, digest|
        actual = sha256(File.join(checkout, path))
        raise Error, "oracle source #{path} is #{actual}, pins.yml requires #{digest}" unless actual == digest
      end
    end

    def verify_lock!
      raise Error, "missing #{lockfile}; run scripts/oracle/setup.rb" unless File.exist?(lockfile)

      expected = sha256(@lock)
      actual = sha256(lockfile)
      raise Error, "oracle lock #{actual} differs from oracle.gemfile.lock #{expected}" unless actual == expected
    end

    def verify!
      verify_checkout!
      verify_lock!
    end

    def identity
      {
        "plurimath_repository" => pins.fetch("plurimath").fetch("repository"),
        "plurimath_commit" => commit,
        "lock_sha256" => sha256(@lock),
        "worker_sha256" => Digest::SHA256.hexdigest(WORKER_SOURCES.map { |path| File.binread(path) }.join),
        "pins_sha256" => sha256(PINS),
      }
    end

    def command
      [RbConfig.ruby, WORKER]
    end

    # Environment for the child: the oracle bundle only, nothing inherited
    # from the latexmath bundle that started the capture.
    def child_env
      base = defined?(Bundler) ? Bundler.unbundled_env : ENV.to_h
      cleared = ENV.keys.to_h { |key| [key, nil] }
      cleared.merge(base).merge("BUNDLE_GEMFILE" => gemfile)
    end

    private

    def sha256(path)
      Digest::SHA256.file(path).hexdigest
    end

    def git(*args)
      out, status = Open3.capture2("git", "-C", checkout, *args)
      raise Error, "git #{args.join(' ')} failed in #{checkout}" unless status.success?

      out.strip
    end
  end
end
