module Latexmath
  module Common
    class Number < Latexmath::Common::Object
      def initialize(number)
        @number = number
      end

      def larger(other)
        value_of > other.value_of ? self : other
      end

      def value_of
        @number
      end
    end
  end
end
