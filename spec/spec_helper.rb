require 'bundler/setup'
require 'rspec/matchers'
require 'equivalent-xml'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

if ENV['TEST_OPAL'] == '1'
  require 'mini_racer'

  puts "* Executing specs for Opal"

  $context = MiniRacer::Context.new
  $context.eval File.read "dist/latexmath.js"
  $context.attach 'console.log', proc { |arg| puts arg }

  # A shim Latexmath module that actually executes the JS file.
  module Latexmath
    def self.fixnils str
      str.gsub('{"$$id":4}', 'Opal.nil')
    end

    class Tokenizer
      def initialize data; @data = data; end
      def tokenize; $context.eval("Opal.Latexmath.Tokenizer.$new(#{@data.to_json}).$tokenize()"); end
    end
    class Aggregator
      def initialize data; @data = data; end
      def aggregate; $context.eval("Opal.Latexmath.Aggregator.$new(#{@data.to_json}).$aggregate()"); end
    end
    class Converter
      def initialize data; @data = data; end
      def convert; $context.eval("Opal.Latexmath.Converter.$new(#{Latexmath.fixnils(@data.to_json)}).$convert()"); end
    end
  end
else
  require 'latexmath'
end
