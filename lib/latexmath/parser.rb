# frozen_string_literal: true

require "parsanol"
require_relative "version"

# The LaTeX stage parser, backed by a compiled Parsanol (PARG) grammar
# artifact generated from the pinned legacy Plurimath grammar.
#
# What is here is the grammar artifact, its declared syntax bindings and the
# internal raw-tree boundary (Latexmath::RawParser) that parity replay
# compares with the legacy Plurimath parser. The public Latexmath.parse,
# returning the typed LaTeX model, is built on top of it later. See
# docs/parser-contract.adoc.
#
# This file is separate from lib/latexmath.rb, which still loads the 0.1.x
# LaTeX-to-MathML converter.
module Latexmath
  autoload :Artifact, "latexmath/parser/artifact"
  autoload :Configuration, "latexmath/parser/configuration"
  autoload :Engine, "latexmath/parser/engine"
  autoload :Preprocessor, "latexmath/parser/preprocessor"
  autoload :RawParser, "latexmath/parser/raw_parser"

  @artifacts = nil
  @artifacts_lock = Mutex.new

  class << self
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
