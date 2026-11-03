# frozen_string_literal: true

require "htmlentities"

module Latexmath
  # Maps positions in the preprocessed text back to the caller's text.
  #
  # It runs the steps of Preprocessor.call again, each as a scan that
  # records, for every character it writes, the caller character it came
  # from: a character that passes through keeps its origin; the characters
  # of a replacement (a decoded or encoded entity, "\\ " for an encoded
  # newline, a restored \text group) start at the origin of the text they
  # replace, and a restored group's characters map one to one onto the
  # caller's group. Removed text leaves no characters behind, so a position
  # after it maps to the caller character that follows it.
  #
  # Only used to report refusals; the grammar input itself always comes
  # from Preprocessor.call. ParseError positions are mapped only when this
  # scan writes exactly the bytes Preprocessor.call wrote.
  #
  # Internal.
  module SourceMap
    FLAVOR = "xhtml1" # HTMLEntities.new's default, as Preprocessor::ENTITIES
    DECODE = HTMLEntities::Decoder.new(FLAVOR).instance_variable_get(:@entity_regexp)
    NAMES = HTMLEntities::MAPPINGS.fetch(FLAVOR)
    # HTMLEntities' :hexadecimal encoding: the basic characters and every
    # character outside U+0020..U+007E.
    ENCODE = /[<>'"&]|[^\u{20}-\u{7E}]/

    # Preprocessor.gsub_space_and_unicodes, as [pattern, literal replacement].
    STEPS = [
      [/((?<!\\) )|\n+/, ""],
      [/\\\\ /, "\\\\"],
      [/&#x26;/, "&"],
      [/&#x22;/, "\""],
      [/(?<!\\\\)\\&#xa;/, "\\ "],
      [/&#xa;/, ""],
    ].freeze

    module_function

    # [preprocessed text, origins] for the normalized UTF-8 caller +input+:
    # origins[i] is the caller character offset of preprocessed character i,
    # and origins[text.length] is input.length.
    def call(input)
      originals = Preprocessor.text_groups(input).map { |range| [input[range], range.begin] }
      text = input
      map = (0..input.length).to_a
      text, map = scan(text, map, DECODE) { |m| decode(m) }
      text, map = scan(text, map, ENCODE) { |m| encode(m[0]) }
      STEPS.each { |pattern, replacement| text, map = scan(text, map, pattern) { replacement } }
      restore_groups(text, map, originals)
    end

    # The caller character offset of character +char+ of +text+ (the
    # preprocessed text of +input+), or nil when the mapping does not
    # reproduce +text+.
    def caller_char(input, text, char)
      mapped, map = call(input)
      return nil unless mapped.b == text.b && char && char <= mapped.length

      map[char]
    end

    def scan(text, map, pattern)
      out = +""
      origins = []
      pos = 0
      while (m = pattern.match(text, pos))
        start = m.begin(0)
        out << text[pos...start]
        origins.concat(map[pos...start])
        replacement = yield(m)
        out << replacement
        origins.concat([map[start]] * replacement.length)
        pos = m.end(0)
      end
      out << text[pos..]
      origins.concat(map[pos..])
      [out, origins]
    end

    # HTMLEntities::Decoder#decode for one match.
    def decode(match)
      if match[1] && (codepoint = NAMES[match[1]])
        codepoint.chr(Encoding::UTF_8)
      elsif match[2]
        match[2].to_i(10).chr(Encoding::UTF_8)
      elsif match[3]
        match[3].to_i(16).chr(Encoding::UTF_8)
      else
        match[0]
      end
    end

    def encode(char)
      "&#x#{char.codepoints.first.to_s(16)};"
    end

    # Preprocessor.replace_text_groups: the n-th group found in +text+ gives
    # way to the n-th group of the caller's input, character for character.
    def restore_groups(text, map, originals)
      out = +""
      origins = []
      pos = 0
      Preprocessor.text_groups(text).each do |range|
        out << text[pos...range.begin]
        origins.concat(map[pos...range.begin])
        group, start = originals.shift
        if group
          out << group
          origins.concat((start...(start + group.length)).to_a)
        end
        pos = range.end + 1
      end
      out << text[pos..]
      origins.concat(map[pos..])
      [out, origins]
    end
  end
end
