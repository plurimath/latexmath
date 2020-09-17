module Latexmath
  module Core
    class State
      attr_accessor :unlocked
      #======================================================================
      # Specialized versions of lookup & assign for dealing with definitions

      ACTIVE_OR_CS = [
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 1, 0, 0,
        1, 0]
      LETTER_OR_OTHER = [
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 1,
        1, 0, 0, 0,
        0, 0]

      # options:
      #     catcodes: standard|style|none
      #     stomach: a Stomach object.
      #     model: a Mod el object.
      def initialize(params = {})
        @catcodes = params.fetch(:catcodes, 'standard')
        @meaning = {}

        @value = {}
        # Note that "100" is hardwired into TeX, The Program!!!
        @value['MAX_ERRORS'] = 100
        @value['VERBOSITY']  = 0
        # Standard TeX units, in scaled points
        @value['UNITS'] = {
            "pt" => 65536, "pc" => 12 * 65536, "in" => 72.27 * 65536, "bp" => 72.27 * 65536 / 72,
            "cm" => 72.27 * 65536 / 2.54,     "mm" => 72.27 * 65536 / 2.54 / 10, "dd" => 1238 * 65536 / 1157,
            "cc" => 12 * 1238 * 65536 / 1157, "sp" => 1,
            "px" => 72.27 * 65536 / 72    # Assume px=bp ?
        }

        if @catcodes.match?(/^(standard|style)/)
          # Setup default catcodes.
          @catcode = {
            "\\" => Token::CC_ESCAPE, "{" => Token::CC_BEGIN, "}" => Token::CC_END, "\$" => Token::CC_MATH,
            "&" => Token::CC_ALIGN, "\r" => Token::CC_EOL,   "#"  => Token::CC_PARAM, "^" => Token::CC_SUPER,
            "_" => Token::CC_SUB,   " "  => Token::CC_SPACE, "\t" => Token::CC_SPACE, "%" => Token::CC_COMMENT,
            "~" => Token::CC_ACTIVE, 0.chr => Token::CC_ESCAPE, "\f" => Token::CC_ACTIVE
          }

          for c in 'A'.ord..'Z'.ord
            @catcode[c.chr] = Token::CC_LETTER
            @catcode[(c + 'a'.ord - 'A'.ord).chr] = Token::CC_LETTER
          end
        end
      end


      #======================================================================
      # Lookup & assign a character's Catcode
      def lookup_catcode(key)
        @catcode.fetch(key, nil)
      end


      # Lookup & assign a general Value
      # [Note that the more direct $$self{value}{$_[1]}[0]; works, but creates entries
      # this could concievably cause space issues, but timing doesn't show improvements this way]
      def lookup_value(key)
        @value.fetch(key, nil)
      end

      # used for expansion & various queries
      # Since we're not doing digestion here, we don't need to handle mathactive,
      # nor cs let to executable tokens
      # This returns a definition object, or undef

      # merge of @executable_catcode & @PRIMITIVE_NAME
      EXECUTABLE_PRIMITIVE_NAME = [    # [CONSTANT]
        nil,       'Begin', 'End', 'Math',
        'Align',     nil,   nil, 'Superscript',
        'Subscript', nil,   nil, nil,
        nil,       nil,   nil, nil,
        nil,       nil]

      def lookup_definition(token)
        return unless token

        cc = token.catcode
        lookupname = ACTIVE_OR_CS[cc] ? token.to_s : EXECUTABLE_PRIMITIVE_NAME[cc]

        if lookupname && entry = @meaning[lookupname] && defn = entry[0] && !defn.is_a?(Token)
          return defn
        end
      end

      # And a shorthand for installing definitions
      def install_definition(definition, scope)
        token = definition.cs
        cs = Token::PRIMITIVE_NAME[token.catcode] || token.to_s

        if (lookup_value("#{cs}:locked") && unlocked == false)
          s = stomach.gullet.source
          # report if the redefinition seems to come from document source
          if(!defined?(s) || s.match?(/\.(tex|bib)$/)) && s.match?(/\.code\.tex$/)
            raise "Ignoring redefinition of #{cs}"
          end
        end

        assign_internal('meaning', cs, definition, scope)
      end

      def assign_internal(table, key, value, scope)
        if table == 'meaning'
          @meaning[key] = value
        end
      end
    end
  end
end

