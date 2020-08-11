require 'singleton'
module Latexmath
  class Symbol
    include Singleton

    def self.get(symbol)
      instance.symbols[symbol]
    end

    def symbols
      @symbols ||= read_symbols
    end

    private

    def read_symbols
      @symbols = {}
      File.readlines('lib/unimathsymbols.txt').each do |line|
        next if line.start_with?('#')

        columns = line.chop.split('^')
        _unicode = columns[0]
        latex = columns[2]
        unicode_math = columns[3]

        @symbols[latex] = _unicode if latex && !@symbols.include?(latex)
        @symbols[unicode_math] = _unicode if unicode_math && !@symbols.include?(unicode_math)

        matches = columns[-1].match(/=\s+(\\[^,^ ]+),?/)
        if matches
          @symbols[matches[1]] = _unicode unless @symbols[matches[1]]
        end
      end
      @symbols
    end
  end
end
