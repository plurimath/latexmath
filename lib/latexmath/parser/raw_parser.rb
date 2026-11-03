# frozen_string_literal: true

module Latexmath
  # The internal raw-tree boundary: the legacy preprocessing, then the
  # grammar, then the declared syntax bindings, which carry the legacy tree.
  #
  # Internal and for tests and parity replay only; not public API. The
  # public Latexmath.parse, which returns the typed LaTeX model, is built on
  # top of it.
  module RawParser
    # +input+: the normalized UTF-8 caller input; +text+: the grammar input
    # (Preprocessor.call); +tree+: the legacy raw tree (Hashes, Arrays and
    # Parsanol::Slice leaves, with the row-break key restored); +engine+:
    # the engine that produced it.
    Result = Struct.new(:input, :text, :tree, :engine, keyword_init: true)

    module_function

    def parse(input, decimal: ".", engine: :auto)
      entry = entry_for(decimal)
      mode = Engine.resolve(engine)
      normalized = normalize_input(input)
      text = Preprocessor.call(normalized)

      loaded = Latexmath.artifacts
      shape = Engine.run(loaded.parse, entry, grammar_input(text), mode, fallback: engine == :auto)
      bound = loaded.bindings.apply(entry, shape)
      tree = bound.fetch(Configuration::TREE_CAPTURE) do
        raise ArtifactError, "the declared bindings did not produce #{Configuration::TREE_CAPTURE}"
      end
      Result.new(input: normalized, text: text, tree: restore_capture_names(tree), engine: Engine.last_engine)
    end

    def entry_for(decimal)
      Configuration::DECIMAL_ENTRIES.fetch(decimal) do
        raise ArgumentError,
              "unsupported decimal marker #{decimal.inspect} " \
              "(supported: #{Configuration::DECIMAL_ENTRIES.keys.map(&:inspect).join(', ')})"
      end
    end

    # The preprocessed text as UTF-8. Preprocessing returns US-ASCII text
    # when nothing outside \text and \mbox groups is non-ASCII (as
    # the legacy preprocessing does); the native engine gives UTF-8 slices
    # either way, and the Ruby engine's slices take the input's encoding.
    def grammar_input(text)
      text.encoding == Encoding::UTF_8 ? text : text.dup.force_encoding(Encoding::UTF_8)
    end

    # +input+ as valid UTF-8, or an ArgumentError.
    def normalize_input(input)
      raise ArgumentError, "input must be a String, got #{input.class}" unless input.is_a?(String)

      text = input.encoding == Encoding::UTF_8 ? input : input.encode(Encoding::UTF_8)
      raise ArgumentError, "input is not valid UTF-8" unless text.valid_encoding?

      text
    rescue EncodingError => e
      raise ArgumentError, "input cannot be converted to UTF-8: #{e.message}"
    end

    # Renames the captures the grammar had to spell differently
    # (Configuration::CAPTURE_RENAMES) back to their legacy keys, keeping
    # key order.
    def restore_capture_names(tree)
      case tree
      when Hash
        tree.to_h do |key, value|
          [Configuration::CAPTURE_RENAMES.fetch(key, key), restore_capture_names(value)]
        end
      when Array then tree.map { |value| restore_capture_names(value) }
      else tree
      end
    end
  end
end
