module Latexmath
  module Core
    class Token
      # Catcodes
      CC_ESCAPE  = 0
      CC_BEGIN   = 1
      CC_END     = 2
      CC_MATH    = 3
      CC_ALIGN   = 4
      CC_EOL     = 5
      CC_PARAM   = 6
      CC_SUPER   = 7
      CC_SUB     = 8
      CC_IGNORE  = 9
      CC_SPACE   = 10
      CC_LETTER  = 11
      CC_OTHER   = 12
      CC_ACTIVE  = 13
      CC_COMMENT = 14
      CC_INVALID = 15
      # Extended Catcodes for expanded output.
      CC_CS     = 16
      CC_MARKER = 17    # non TeX extension!

      #======================================================================
      # Constructors.




      # [The documentation for constant is a bit confusing about subs,
      # but these apparently DO generate constants; you always get the same one]
      # These are immutable
      # T_BEGIN = bless ['{',  CC_BEGIN], 'LaTeXML::Core::Token';
      # T_END   = bless ['}',  CC_END],   'LaTeXML::Core::Token';
      # T_MATH  = bless ['$',  CC_MATH],  'LaTeXML::Core::Token';
      # T_ALIGN = bless ['&',  CC_ALIGN], 'LaTeXML::Core::Token';
      # T_PARAM = bless ['#',  CC_PARAM], 'LaTeXML::Core::Token';
      # T_SUPER = bless ['^',  CC_SUPER], 'LaTeXML::Core::Token';
      # T_SUB   = bless ['_',  CC_SUB],   'LaTeXML::Core::Token';
      # T_SPACE = bless [' ',  CC_SPACE], 'LaTeXML::Core::Token';
      # T_CR    = bless ["\n", CC_SPACE], 'LaTeXML::Core::Token';

      T_BEGIN = ['{',  CC_BEGIN]
      T_END   = ['}',  CC_END]
      T_MATH  = ['$',  CC_MATH]
      T_ALIGN = ['&',  CC_ALIGN]
      T_PARAM = ['#',  CC_PARAM]
      T_SUPER = ['^',  CC_SUPER]
      T_SUB   = ['_',  CC_SUB]
      T_SPACE = [' ',  CC_SPACE]
      T_CR    = ["\n", CC_SPACE]

      CATCODES = {
        '{': CC_BEGIN,
        '}': CC_END,
        '$':  CC_MATH,
        '&':  CC_ALIGN,
        '#':  CC_PARAM,
        '^':  CC_SUPER,
        '_':  CC_SUB,
        ' ':  CC_SPACE,
        "\n": CC_SPACE
      }

      # #======================================================================
      # # Categories of Category codes.
      # # For Tokens with these catcodes, only the catcode is relevant for comparison.
      # # (if they even make it to a stage where they get compared)
      # our @primitive_catcode = (    # [CONSTANT]
      #   1, 1, 1, 1,
      #   1, 1, 1, 1,
      #   1, 0, 1, 0,
      #   0, 0, 0, 0,
      #   0, 0);
      # our @executable_catcode = (    # [CONSTANT]
      #   0, 1, 1, 1,
      #   1, 0, 0, 1,
      #   1, 0, 0, 0,
      #   0, 1, 0, 0,
      #   1, 0);

      # our @standardchar = (          # [CONSTANT]
      #   "\\",  '{',   '}',   q{$},
      #   q{&},  "\n",  q{#},  q{^},
      #   q{_},  undef, undef, undef,
      #   undef, undef, q{%},  undef,
      #   undef, undef);

      # our @CC_NAME =                 #[CONSTANT]
      #   qw(Escape Begin End Math
      #   Align EOL Parameter Superscript
      #   Subscript Ignore Space Letter
      #   Other Active Comment Invalid
      #   ControlSequence Marker);
      PRIMITIVE_NAME = [
        'Escape',    'Begin', 'End',       'Math',
        'Align',     'EOL',   'Parameter', 'Superscript',
        'Subscript', nil,   'Space',     nil,
        nil,       nil,   nil,       nil,
        nil,       nil
      ]
      # our @CC_SHORT_NAME =           #[CONSTANT]
      #   qw(T_ESCAPE T_BEGIN T_END T_MATH
      #   T_ALIGN T_EOL T_PARAM T_SUPER
      #   T_SUB T_IGNORE T_SPACE T_LETTER
      #   T_OTHER T_ACTIVE T_COMMENT T_INVALID
      #   T_CS
      # );

      # sub T_LETTER { my ($c) = @_; return bless [$c, CC_LETTER], 'LaTeXML::Core::Token'; }
      # sub T_OTHER  { my ($c) = @_; return bless [$c, CC_OTHER],  'LaTeXML::Core::Token'; }
      # sub T_ACTIVE { my ($c) = @_; return bless [$c, CC_ACTIVE], 'LaTeXML::Core::Token'; }
      # sub T_COMMENT { my ($c) = @_; return bless ['%' . ($c || ''), CC_COMMENT], 'LaTeXML::Core::Token'; }
      # sub T_CS { my ($c) = @_; return bless [$c, CC_CS], 'LaTeXML::Core::Token'; }
      # # Illegal: don't use unless you know...
      # sub T_MARKER { my ($t) = @_; return bless [$t, CC_MARKER], 'LaTeXML::Core::Token'; }

      def initialize(token, cc)
        @token = token
        @cc = cc
      end

      # Return the string or character part of the token
      def to_s
        @token
      end

      # Return the catcode of the token.
      def catcode
        @cc
      end

      def explode
      end

      def explode_text
      end

      def untex
      end
    end
  end
end
