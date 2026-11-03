# frozen_string_literal: true

module Latexmath
  # Base class for every error Latexmath raises on purpose, except
  # ArgumentError for invalid arguments.
  class Error < StandardError; end

  # The grammar refused the input.
  #
  # +input+ is the caller's input, as normalized UTF-8, and the offsets are
  # zero-based positions in it: +byte_offset+ in UTF-8 bytes, +char_offset+
  # in characters. They are the position the legacy Plurimath grammar
  # reports, mapped back through the preprocessing (see SourceMap): an
  # entity or other text the preprocessing wrote maps to the start of the
  # caller text it stands for.
  #
  # +grammar_input+ is the text the grammar ran on (the preprocessed text);
  # +grammar_byte_offset+ and +grammar_char_offset+ are the same position in
  # it, as the legacy grammar reports it on either engine. They are for
  # parity replay and diagnostics.
  class ParseError < Error
    attr_reader :input, :byte_offset, :char_offset,
                :grammar_input, :grammar_byte_offset, :grammar_char_offset

    def initialize(message, input:, byte_offset:, char_offset:,
                   grammar_input: nil, grammar_byte_offset: nil, grammar_char_offset: nil)
      super(message)
      @input = input
      @byte_offset = byte_offset
      @char_offset = char_offset
      @grammar_input = grammar_input
      @grammar_byte_offset = grammar_byte_offset
      @grammar_char_offset = grammar_char_offset
    end
  end

  # The engine that ran cannot handle the input's nesting depth: the native
  # engine's recursion limit, or an exhausted Ruby stack. +input+ and
  # +grammar_input+ are set; every offset is nil. This does not claim that
  # the input is invalid.
  class NestingTooDeep < ParseError; end

  # A parse or bindings artifact is missing, malformed, fails its checksum,
  # declares the wrong target or kind, or does not pair with the other.
  # Latexmath never falls back to another artifact.
  class ArtifactError < Error; end

  # engine: :native was requested but Parsanol's native extension is not
  # available on this platform.
  class EngineUnavailable < Error; end
end
