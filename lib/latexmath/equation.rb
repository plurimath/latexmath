module Latexmath
  class Equation
    def initialize(string)
      @latex = string
    end

    def to_mathml
      @latex
    end
  end
end
