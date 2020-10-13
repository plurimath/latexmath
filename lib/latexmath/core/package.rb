module Latexmath
  module Core
    class Package
      #======================================================================
      # Define a LaTeX environment
      # Note that the body of the environment is treated is the 'body' parameter in the constructor.
      ENVIRONMENT_OPTIONS = {
        mode: 1, requireMath: 1, forbidMath: 1,
        properties: 1, nargs: 1, font: 1,
        beforeDigest: 1, afterDigest: 1,
        afterDigestBegin: 1, beforeDigestEnd: 1, afterDigestBody: 1,
        beforeConstruct: 1, afterConstruct: 1,
        reversion: 1, sizer: 1, scope: 1, locked: 1
      }.freeze

      # Define a Macro: Essentially an alias for def expandable
      # For convenience, the 'expansion' can be a string which will be tokenized.
      MACRO_OPTIONS = {
        scope: 1, locked: 1, mathactive: 1,
        protected: 1, outer: 1, long: 1
      }.freeze

      def initialize(state = Latexmath::Core::State.new(catcodes: 'standard'))
        @state = state
      end

      def macro(proto, expansion, options = {})
        check_options("DefMacro (#{proto})", MACRO_OPTIONS, options)
        cs, paramlist = parse_prototype(proto)
        macro_i(cs, paramlist, expansion, options)
      end

      def macro_i(cs, paramlist, expansion, options = [])
        expansion = Latexmath::Core::Tokens.new unless defined?(expansion)

        @state.assign_mathcode(cs: 0x8000, scope: options['scope']) if cs.is_a?(Token) && options['mathactive']

        @state.install_definition(Definition::Expandable.new(cs, paramlist, expansion, options), options['scope'])
      end

      def check_options(operation, allowed, options)
        badops = allowed.keys & options.keys
        raise("#{operation} does not accept options: #{badops.join(', ')}") if badops.any?
      end

      def parse_prototype(proto)
        return proto, nil if proto.is_a?(Latexmath::Core::Token)

        if matches = proto.match(/^\\csname\s+(.*)\\endcsname/)
          cs = Token.new((matches[1]).to_s, Token::CC_CS)
        elsif matches = proto.match(/^(\\[a-zA-Z@]+)/)    # Mach a cs
          cs = Token.new((matches[1]).to_s, Token::CC_CS)
        elsif matches = proto.match(/^(\\.)/)             # Match a single char cs, env name,...
          cs = Token.new((matches[1]).to_s, Token::CC_CS)
        elsif matches = proto.match(/^(.)/)               # Match an active char
          cs = tokenize_internal(matches[1]).unlist
        else
          raise("Definition prototype doesn't have proper control sequence: \"#{proto}\"")
        end

        [cs, proto]
      end

      def tokenize_internal(str)
        @sty_cattable ||= LaTeXML::Core::State.new(catcodes: 'style')
        Latexmath::Core::Mouth.new(str, @sty_cattable).read_tokens
      end
    end
  end
end
