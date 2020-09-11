require 'singleton'
module Latexmath
  class Symbol
    include Singleton

    def self.get(symbol)
      instance.symbols[symbol]
    end

    def symbols
      if RUBY_ENGINE == 'opal'
        require 'unimathsymbols'
        require 'native'
        @symbols ||= Native::Object.new(`globalThis.unimathsymbols`)
      else
        @symbols ||= Latexmath::Constants::SYMBOLS
      end
    end

  end
end
