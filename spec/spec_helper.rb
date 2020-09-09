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
  require 'execjs'

  puts "* Executing specs for Opal"

  $context = ExecJS.compile File.read "dist/latexmath.js"

  # A shim Latexmath module that actually executes the JS file.
  module Latexmath
    def self.fixinils str
      str.gsub('null', 'Opal.nil').gsub('{"$$id":4}', 'Opal.nil')
    end

    def self.fixonils str
      JSON.load(str.to_json.gsub('{"$$id":4}', 'null'))
    end

    class Tokenizer
      def initialize data; @data = data; end
      def tokenize; Latexmath.fixonils $context.eval("Opal.Latexmath.Tokenizer.$new(#{Latexmath.fixinils @data.to_json}).$tokenize()"); end
    end
    class Aggregator
      def initialize data; @data = data; end
      def aggregate; Latexmath.fixonils $context.eval("Opal.Latexmath.Aggregator.$new(#{Latexmath.fixinils @data.to_json}).$aggregate()"); end
    end
    class Converter
      def initialize data; @data = data; end
      def convert; Latexmath.fixonils $context.eval("Opal.Latexmath.Converter.$new(#{Latexmath.fixinils @data.to_json}).$convert()"); end
    end
  end
else
  require 'latexmath'
end
