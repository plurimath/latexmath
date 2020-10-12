module Latexmath
  module Core
    class Stomach
      def initialize(options)
        @gullet = Latexmath::Core::Gullet.new(options)
        @boxing = []
        @token_stack = []

        # $STATE->assignValue(MODE              => 'text',           'global');
        # $STATE->assignValue(IN_MATH           => 0,                'global');
        # $STATE->assignValue(PRESERVE_NEWLINES => 1,                'global');
        # $STATE->assignValue(afterGroup        => [],               'global');
        # $STATE->assignValue(afterAssignment   => undef,            'global');
        # $STATE->assignValue(groupInitiator    => 'Initialization', 'global');
        # # Setup default fonts.
        # $STATE->assignValue(font     => LaTeXML::Common::Font->textDefault(), 'global');
        # $STATE->assignValue(mathfont => LaTeXML::Common::Font->mathDefault(), 'global');
      end
    end
  end
end
