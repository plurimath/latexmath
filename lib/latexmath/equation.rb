module Latexmath
  class Equation
    def initialize(string)
      @latex = string
    end

    def to_mathml
      tokenizer = Tokenizer.new(@latex)
      tokens = tokenizer.tokenize
      aggregate = Aggregator.new(tokens).aggregate
      Converter.new(aggregate).convert(tokenizer.display)
    end
  end
end
