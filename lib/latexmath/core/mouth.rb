module Latexmath
  module Core
    class Mouth
      def initialize(str, _options = {})
        @state = Latexmath::Core::State.new(catcodes: 'standard')
        @lineno = 0
        @colno  = 0
        @chars = []
        @nchars = 0

        open_string(str)
      end

      # Read the next token, or undef if exhausted.
      # Note that this also returns COMMENT tokens containing source comments,
      # and also locator comments (file, line# info).
      # LaTeXML::Core::Gullet intercepts them and passes them on at appropriate times.
      def read_token
        loop do
          if @colno >= @nchars
            @lineno += 1
            @colno = 0
            line = next_line

            unless line # Exhausted the input.
              @at_eof = 1
              @chars  = []
              @nchars = 0
              return
            end
            # Remove trailing space, but NOT a control space!  End with CR (not \n) since this gets tokenized!
            line.gsub!(/((\\ )*)\s*$/, '') # Original perl regexp: s/((\\ )*)\s*$/$1/s
            # Then append the appropriaate \endlinechar, or "\r"
            if eol = @state.lookup_definition(Token.new("\endlinechar", Token::CC_CS))
              eol = eol.value
              line += eol.chr if eol > 0
            else
              line += "\r"
            end

            @chars = split_chars(line)
            @nchars = @chars.size

            while @colno < @nchars && ((@state.lookup_catcode(@chars[@colno]) || Token::CC_OTHER) == Token::CC_SPACE)

              @colno += 1
            end

            # # # Sneak a comment out, every so often.
            # if (((@lineno % 25) == 0) && @state.lookup_value('INCLUDE_COMMENTS'))
            #   return T_COMMENT("**** " . (@shortsource || 'String') . " Line #{@lineno} ****")
            # end
          end

          if @skipping_spaces # Skip spaces now
            while (ch, cc = next_char) && ch && cc == Token::CC_SPACE
            end
            @colno -= 1 if @colno < @nchars
            if defined?(cc) && cc == Token::CC_EOL
              if (@state.lookup_value('PRESERVE_NEWLINES') || 0) > 1

              else
                next_char
                @colno -= 1 if @colno < @nchars
              end
            end
            @skipping_spaces = false
          end

          ch, cc = next_char
          token = (defined?(cc) ? dispatch(ch, cc) : nil)
          token = Core::Token.new(ch, cc) if token.nil?
          return token if token
        end
      end

      # **********************************************************************
      # Read all tokens until a token equal to $until (if given), or until exhausted.
      # Returns an empty Tokens list, if there is no input
      def read_tokens
        @tokens = []
        while token = read_token
          @tokens.push(token)
        end
        @tokens.pop while @tokens.size > 0 && @tokens[-1].catcode == Token::CC_SPACE
        Latexmath::Core::Tokens.new(@tokens)
      end

      def handle_comment
        n = @colno
        @colno = @nchars
        comment = @chars[n..(@nchars - 1)]
        comment.gsub!(/^\s+/, '')
        comment.gsub!(/\s+$/, '')
        comment && @state.lookup_value('INCLUDE_COMMENTS') ? Token.new(comment, Token::CC_COMMENT) : nil
      end

      def handle_escape
        ch, cc = next_char
        cs = "\\#{ch}"
        if defined?(cc) && cc == Token::CC_LETTER
          while (ch, cc = next_char) && ch && cc == Token::CC_LETTER
            cs += ch
          end
          @skipping_spaces = true
          @colno -= 1
        end

        Token.new(cs, Token::CC_CS)
      end

      def handle_space
        while (ch, cc = next_char) && ch && (cc == Token::CC_SPACE || cc == Token::CC_EOL)
        end
        @colno -= 1 if @colno < @nchars
        Token.new(' ', Token::CC_SPACE)
      end

      def handle_EOL
        token = if @colno == 1
                  Token.new('\\par', Token::CC_CS)
                else
                  if @state.lookup_value('PRESERVE_NEWLINES')
                    Token.new("\n", Token::CC_SPACE)
                  else
                    Token.new(' ', Token::CC_SPACE)
                  end
                end

        @colno = @nchars
        token
      end

      # # # Dispatch table for catcodes.

      # # Possibly want to think about caching (common) letters, etc to keep from
      # # creating tokens like crazy... or making them more compact... or ???
      def dispatch(ch, cc)
        case cc
        when 0
          handle_escape
        when 1
          Token.new(ch, Token::CC_BEGIN)
        when 2
          Token.new(ch, Token::CC_END)
        when 3
          Token.new(ch, Token::CC_MATH)
        when 4
          Token.new(ch, Token::CC_ALIGN)
        when 5
          handle_EOL
        when 6
          Token.new(ch, Token::CC_PARAM)
        when 7
          Token.new(ch, Token::CC_SUPER)
        when 8
          Token.new(ch, Token::CC_SUB)
        when 9
          nil
        when 10
          handle_space
        when 11
          Token.new(ch, Token::CC_LETTER)
        when 12
          Token.new(ch, Token::CC_OTHER)
        when 13
          Token.new(ch, Token::CC_ACTIVE)
        when 14
          handle_comment
        when 15
          Token.new(ch, Token::CC_OTHER)
        end
      end

      # Get the next character & it's catcode from the input,
      # handling TeX's "^^" encoding.
      # Note that this is the only place where catcode lookup is done,
      # and that it is somewhat `inlined'.
      def next_char
        if @colno < @nchars
          ch = @chars[@colno]
          @colno += 1
          cc = @state.lookup_catcode(ch) || Token::CC_OTHER

          if cc == Token::CC_SUPER && (@colno + 1) < @nchars && ch == @chars[@colno]
            if (@colno + 2) < @nchars && c1 = @chars[@colno + 1].match?(/^[0-9a-f]$/) && c2 = @chars[@colno + 2].match?(/^[0-9a-f]$/)
              ch = "#{c1}#{c2}".hex.chr
              4.times { @chars.delete_at(@colno) }
              @chars.insert(@colno, ch)
              @nchars -= 3
            else # OR ^^ followed by a SINGLE Control char type code???
              c = @chars[@colno + 1]
              cn = c.ord
              ch = (cn + (cn >= 64 ? -64 : 64)).chr
              3.times { @chars.delete_at(@colno) }
              @chars.insert(@colno, ch)
              @nchars -= 2
            end
            cc = @state.lookup_catcode(ch) || Token::CC_OTHER
          end
          [ch, cc]
        else
          [nil, nil]
        end
      end

      # This is (hopefully) a correct way to split a line into "chars",
      # or what is probably more desired is "Grapheme clusters" (even "extended")
      # These are unicode characters that include any following combining chars, accents & such.
      # I am thinking that when we deal with unicode this may be the most correct way?
      # If it's not the way XeTeX does it, perhaps, it must be that ALL combining chars
      # have to be converted to the proper accent control sequences!
      def split_chars(line)
        line.scan(/\X/)
      end

      def next_line
        return unless @buffer.is_a?(Array)
        return if @buffer.empty?

        line = @buffer.shift
        @buffer.empty? ? "#{line}\r" : line # No CR on last line!
      end

      def open_string(str)
        if defined?(str)
          if str.valid_encoding?
          elsif true
          end
        end

        @string = str
        @buffer = defined?(str) ? split_lines(str) : []
      end

      # # This is (hopefully) a platform independent way of splitting a string
      # # into "lines" ending with CRLF, CR or LF (DOS, Mac or Unix).
      # # Note that TeX considers newlines to be \r, ie CR, ie ^^M
      def split_lines(str)
        str.gsub!(/(?:\015\012|\015|\012)/, "\r") # Normalize remaining. Perl: s/(?:\015\012|\015|\012)/\r/sg
        str.split("\r")                    # And split.
      end
    end
  end
end
