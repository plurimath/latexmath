# frozen_string_literal: true

require "htmlentities"

module Latexmath
  # The legacy LaTeX input preprocessing (Plurimath::Latex::Parser at the
  # pinned commit, see docs/parser-contract.adoc), step for step:
  #
  # 1. remember every \mbox{...} and \text{...} group of the input;
  # 2. decode HTML entities, then encode the whole text with hexadecimal
  #    entities;
  # 3. remove spaces that do not follow a backslash and runs of newlines;
  #    turn "\\ " into "\\"; turn &#x26; and &#x22; back into & and ";
  #    turn a backslash before an encoded newline into "\ " unless it ends
  #    a row break; drop the remaining encoded newlines;
  # 4. put the remembered groups back as the caller wrote them.
  #
  # Internal.
  module Preprocessor
    TEXT_REGEX = %r(\\(?:mbox|text)\{[^}]+\})
    ENTITIES = HTMLEntities.new

    module_function

    # The grammar input for the normalized UTF-8 caller +input+.
    def call(input)
      text_functions = input.scan(TEXT_REGEX)
      text = ENTITIES.encode(ENTITIES.decode(input), :hexadecimal)
      text = gsub_space_and_unicodes(text)
      text.gsub(TEXT_REGEX) { |_str| text_functions.shift }
    end

    def gsub_space_and_unicodes(text)
      text
        .gsub(/((?<!\\) )|\n+/, "")
        .gsub("\\\\ ", "\\\\\\\\")
        .gsub("&#x26;", "&")
        .gsub("&#x22;", "\"")
        .gsub(/(?<!\\\\)\\&#xa;/, "\\ ")
        .gsub("&#xa;", "")
    end
  end
end
