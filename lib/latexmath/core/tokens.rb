module Latexmath
  module Core
    class Tokens
      def initialize(tokens)
        @tokens = tokens
      end

      def to_a
        @tokens
      end
    end
  end
end
