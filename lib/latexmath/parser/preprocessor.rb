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
    TEXT_OPEN = /\\(?:mbox|text)\{/
    TEXT_OPEN_LENGTH = "\\mbox{".length
    ENTITIES = HTMLEntities.new

    module_function

    # The grammar input for the normalized UTF-8 caller +input+.
    def call(input)
      text_functions = text_groups(input).map { |range| input[range] }
      text = ENTITIES.encode(ENTITIES.decode(input), :hexadecimal)
      text = gsub_space_and_unicodes(text)
      replace_text_groups(text) { text_functions.shift }
    end

    # Legacy: the matches of %r(\\(?:mbox|text)\{[^}]+\}), as index ranges.
    # Each match runs from an opener to the first "}" after it, with at
    # least one character between; an opener followed directly by "}" does
    # not match there and the search goes on one character later. Written
    # out without the backtracking regexp, which is polynomial on input
    # with many unclosed openers.
    def text_groups(text)
      groups = []
      pos = 0
      while (start = text.index(TEXT_OPEN, pos))
        body = start + TEXT_OPEN_LENGTH
        close = text.index("}", body) or break
        if close == body
          pos = start + 1
        else
          groups << (start..close)
          pos = close + 1
        end
      end
      groups
    end

    # Legacy: text.gsub(TEXT_REGEX) { ... }, keeping its result encoding.
    def replace_text_groups(text)
      out = String.new(encoding: text.encoding)
      pos = 0
      text_groups(text).each do |range|
        out << text[pos...range.begin] << yield.to_s
        pos = range.end + 1
      end
      out << text[pos..]
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
