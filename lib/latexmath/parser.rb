# frozen_string_literal: true

require "parsanol"
require_relative "version"

# The LaTeX stage parser, backed by a compiled Parsanol (PARG) grammar
# artifact generated from the pinned legacy Plurimath grammar.
#
# Latexmath.parse(input, decimal:, engine:) returns the typed LaTeX model, a
# Latexmath::Model::Document. Underneath are the grammar artifact, its
# declared syntax bindings and the internal raw-tree boundary
# (Latexmath::RawParser) that parity replay compares with the legacy
# Plurimath parser. See docs/parser-contract.adoc and
# docs/model-contract.adoc.
#
# lib/latexmath.rb requires this file.
module Latexmath
  autoload :Artifact, "latexmath/parser/artifact"
  autoload :Configuration, "latexmath/parser/configuration"
  autoload :Engine, "latexmath/parser/engine"
  autoload :Model, "latexmath/model"
  autoload :Preprocessor, "latexmath/parser/preprocessor"
  autoload :RawParser, "latexmath/parser/raw_parser"
  autoload :SourceMap, "latexmath/parser/source_map"
  autoload :Symbols, "latexmath/symbols"
  autoload :Unwrap, "latexmath/parser/unwrap"

  @artifacts = nil
  @artifacts_lock = Mutex.new

  class << self
    # Parses LaTeX math +input+ (a String, valid UTF-8 or convertible to it)
    # into the typed model: a Model::Document whose +expression+ is the
    # formula's tree and +decimal+ the decimal marker it was parsed with
    # ("." , "," or "\u066B"). Input with no formula (empty, or only
    # spaces and newlines, which the preprocessing removes) gives a
    # Document whose expression is nil.
    #
    # +engine+: :auto (native when available, else Ruby), :native or :ruby.
    # Raises ParseError (offsets into +input+), NestingTooDeep,
    # ArgumentError, ArtifactError or EngineUnavailable.
    def parse(input, decimal: ".", engine: :auto)
      text = RawParser.normalize_input(input)
      RawParser.entry_for(decimal)
      return Model::Document.new(decimal: decimal) if Preprocessor.call(text).empty?

      raw = RawParser.parse(text, decimal: decimal, engine: engine)
      build(raw, decimal, text)
    end

    # The verified, paired parse and Ruby bindings artifacts (internal).
    def artifacts
      artifact_store.fetch
    end

    # Points Latexmath at other artifacts (for tests). The next parse loads
    # and verifies them.
    def use_artifacts(path, bindings_path)
      artifact_store.use(path, bindings_path)
    end

    def artifact_paths
      [artifact_store.path, artifact_store.bindings_path]
    end

    # The engine (:native or :ruby) of the last parser run on this thread,
    # or nil before the first one.
    def last_engine
      Engine.last_engine
    end

    def native_available?
      Engine.native_available?
    end

    private

    def build(raw, decimal, text)
      Model::Document.new(expression: raw.model, decimal: decimal)
    rescue SystemStackError
      raise NestingTooDeep.new("LaTeX input nests too deeply to build its model (Ruby stack exhausted)",
                               input: text, byte_offset: nil, char_offset: nil, grammar_input: raw.text)
    end

    def artifact_store
      @artifacts_lock.synchronize do
        @artifacts ||= Artifact.new(Configuration::DEFAULT_ARTIFACT_PATH,
                                    Configuration::DEFAULT_BINDINGS_PATH)
      end
    end
  end
end

# Installs a hook into Parsanol at load time, so these are required, not
# autoloaded.
require_relative "parser/errors"
require_relative "parser/native_recursion_guard"
