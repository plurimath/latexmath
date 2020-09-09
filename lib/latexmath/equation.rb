module Latexmath
  class Equation
    def initialize(string)
      @latex = string
    end

    def to_mathml
      tokens = Tokenizer.new(@latex).tokenize
      aggregate = Aggregator.new(tokens).aggregate
      Converter.new(aggregate).convert
    end
  end
end
