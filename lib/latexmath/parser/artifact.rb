# frozen_string_literal: true

require "json"

module Latexmath
  # The compiled grammar and its declared Ruby bindings, loaded, verified
  # and paired once per pair of paths.
  class Artifact
    Loaded = Struct.new(:parse, :bindings)

    # Loads the Parsanol::PARG::Artifact at +path+ and checks it has an
    # entry for every decimal marker.
    def self.load_parse(path)
      raise ArtifactError, "artifact not found: #{path}" unless File.file?(path)

      artifact = Parsanol::PARG::Artifact.load(path)
      missing = Configuration::DECIMAL_ENTRIES.values - artifact.entries
      unless missing.empty?
        raise ArtifactError, "artifact #{path} lacks required entries: #{missing.join(', ')}"
      end

      artifact
    rescue JSON::ParserError => e
      raise ArtifactError, "artifact #{path} is not valid JSON: #{e.message.lines.first&.strip}"
    rescue Parsanol::PARG::Error, SystemCallError, KeyError, TypeError, NoMethodError => e
      raise ArtifactError, "artifact #{path} is invalid: #{e.class}: #{e.message}"
    end

    # Loads the Ruby bindings artifact at +path+: kind, checksum, target and
    # binding version are verified, then it is paired with +parse+ (same
    # grammar, version and source hash). Every entry must declare the tree
    # capture.
    def self.load_bindings(path, parse)
      raise ArtifactError, "bindings artifact not found: #{path}" unless File.file?(path)

      bindings = Parsanol::PARG::Bindings::Artifact.from_json(File.read(path, encoding: "UTF-8"),
                                                              target: "ruby")
      bindings.pair_with!(parse)
      Configuration::DECIMAL_ENTRIES.each_value do |entry|
        declared = bindings.bindings(entry).map { |b| b["capture"] }
        next if declared.include?(Configuration::TREE_CAPTURE.to_s)

        raise ArtifactError, "bindings artifact #{path} does not bind #{Configuration::TREE_CAPTURE} for entry #{entry}"
      end
      bindings
    rescue JSON::ParserError => e
      raise ArtifactError, "bindings artifact #{path} is not valid JSON: #{e.message.lines.first&.strip}"
    rescue Parsanol::PARG::Error, SystemCallError, KeyError, TypeError, NoMethodError => e
      raise ArtifactError, "bindings artifact #{path} is invalid: #{e.class}: #{e.message}"
    end

    attr_reader :path, :bindings_path

    def initialize(path, bindings_path)
      @path = path
      @bindings_path = bindings_path
      @loaded = nil
      @lock = Mutex.new
    end

    # Points at other artifacts (mainly for tests); the next #fetch loads them.
    def use(path, bindings_path)
      @lock.synchronize do
        @path = path.to_s
        @bindings_path = bindings_path.to_s
        @loaded = nil
      end
    end

    # The loaded pair, loaded on first use.
    def fetch
      @lock.synchronize do
        @loaded ||= begin
          parse = self.class.load_parse(@path)
          Loaded.new(parse, self.class.load_bindings(@bindings_path, parse))
        end
      end
    end
  end
end
