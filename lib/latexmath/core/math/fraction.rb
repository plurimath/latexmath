module Latexmath
  module Core
    module Math
      class Fraction
        def initialize(numerator, denominator)
          @denominator = denominator
          @numerator = numerator
        end

        def w
          @numerator.width.larger(denominator.width)
        end

        def d
          @denominator.total_height.multiply(0.5)
        end

        def h
          @numerator.total_height.add(d)
        end
      end
    end
  end
end
