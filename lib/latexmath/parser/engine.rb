# frozen_string_literal: true

module Latexmath
  # Runs the grammar on the native or Ruby Parsanol engine with the legacy
  # grammar's settings (Parsanol's default, strict memo policy), maps
  # failures to Latexmath errors and records the engine that produced the
  # result per thread.
  #
  # Internal.
  module Engine
    LAST_ENGINE_KEY = :latexmath_last_engine
    OPENING = "([{".chars.freeze
    CLOSING = ")]}".chars.freeze

    module_function

    def last_engine
      Thread.current[LAST_ENGINE_KEY]
    end

    def native_available?
      Parsanol::Native.available?
    rescue LoadError, StandardError
      false
    end

    # The engine (:native or :ruby) that +engine+ (one of ENGINES) runs.
    def resolve(engine)
      case engine
      when :auto then native_available? ? :native : :ruby
      when :ruby then :ruby
      when :native
        return :native if native_available?

        raise EngineUnavailable,
              "engine: :native requested but the Parsanol native extension " \
              "is not available on this platform (#{RUBY_PLATFORM}, Ruby #{RUBY_VERSION})"
      else
        raise ArgumentError,
              "unknown engine #{engine.inspect} (use #{Configuration::ENGINES.map(&:inspect).join(', ')})"
      end
    end

    # Parses +text+ from +entry+ of the parse artifact +artifact+ on +mode+
    # and returns the parse shape. Under +fallback+ (engine: :auto) input
    # too deep for the native engine is rerun on Ruby.
    def run(artifact, entry, text, mode, fallback:)
      shape, ran = run_with_fallback(artifact, entry, text, mode, fallback: fallback)
      record(ran)
      shape
    end

    def run_with_fallback(artifact, entry, text, mode, fallback:)
      if mode == :native && too_deep_for_native_thread?(text)
        record(:native)
        unless fallback
          raise native_too_deep(text, "nesting depth over #{Configuration::THREAD_NATIVE_DEPTH} off the main thread")
        end

        return [run_mode(artifact, entry, text, :ruby), :ruby]
      end

      [run_mode(artifact, entry, text, mode), mode]
    rescue NativeRecursionLimit => e
      record(:native)
      raise native_too_deep(text, e.message) unless fallback

      [run_mode(artifact, entry, text, :ruby), :ruby]
    rescue NestingTooDeep
      raise unless fallback && mode == :native

      [run_mode(artifact, entry, text, :ruby), :ruby]
    end

    def too_deep_for_native_thread?(text)
      return false if Thread.current.equal?(Thread.main)

      depth = 0
      max = 0
      text.each_char do |char|
        if OPENING.include?(char)
          depth += 1
          max = depth if depth > max
        elsif CLOSING.include?(char)
          depth -= 1 if depth.positive?
        end
      end
      max > Configuration::THREAD_NATIVE_DEPTH
    end

    def native_too_deep(text, detail)
      NestingTooDeep.new(
        "LaTeX input nests deeper than the native engine's recursion limit " \
        "(#{detail}); use engine: :ruby or engine: :auto",
        input: text, byte_offset: nil, char_offset: nil,
      )
    end

    def run_mode(artifact, entry, text, mode)
      root = artifact.root_atom(entry)
      reporter = nil
      if mode == :native
        NativeRecursionGuard.watch { Parsanol::Native.parse(root, text) }
      else
        reporter = Parsanol::ErrorReporter::Deepest.new
        root.parse(text, reporter: reporter)
      end
    rescue Parsanol::ParseFailed => e
      record(mode)
      raise parse_error(e, reporter, text)
    rescue SystemStackError
      record(mode)
      raise NestingTooDeep.new(
        "LaTeX input nests too deeply for the #{mode} engine (Ruby stack exhausted)",
        input: text, byte_offset: nil, char_offset: nil,
      )
    rescue Parsanol::PARG::Error, Parsanol::GrammarError, Parsanol::Native::UnsupportedGrammar => e
      raise ArtifactError, "the grammar artifact cannot be used: #{e.class}: #{e.message}"
    end

    # The legacy grammar runs on the native engine, whose failure reports
    # the furthest position any branch reached. The Ruby engine's raised
    # cause is the root failure; its Deepest reporter holds the furthest
    # leaf, which is the same position.
    def parse_error(error, reporter, text)
      cause = reporter&.deepest_cause || error.parse_failure_cause
      byte = cause&.position
      char = byte && text.byteslice(0, byte).force_encoding(Encoding::UTF_8).scrub.length
      where = byte ? " at character #{char} (byte #{byte})" : ""
      ParseError.new("LaTeX input rejected#{where}: #{error.message.lines.first.to_s.strip[0, 200]}",
                     input: text, byte_offset: byte, char_offset: char)
    end

    def record(mode)
      Thread.current[LAST_ENGINE_KEY] = mode
    end

    private_class_method :run_with_fallback, :native_too_deep, :run_mode, :parse_error,
                         :record, :too_deep_for_native_thread?
  end
end
