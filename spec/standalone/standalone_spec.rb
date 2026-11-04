# frozen_string_literal: true

require "open3"
require "rbconfig"

# `require "latexmath"` in a fresh process: the stage parser and model load
# on their own, without Plurimath and without the removed 0.1.x converter.
RSpec.describe "require \"latexmath\"" do
  root = File.expand_path("../..", __dir__)

  def run_ruby(root, script)
    Open3.capture3(RbConfig.ruby, "-I", File.join(root, "lib"), "-rlatexmath", "-e", script, chdir: root)
  end

  it "parses into the typed model without loading Plurimath" do
    out, err, status = run_ruby(root, <<~RUBY)
      d = Latexmath.parse("x^2", engine: :ruby)
      raise "Plurimath is loaded" if defined?(Plurimath)
      power = d.expression.power
      puts [d.class, power.symbols.spelling, power.supscript.number, Latexmath::VERSION].join(" ")
    RUBY
    expect(status).to be_success, err
    expect(out).to eq("Latexmath::Model::Document x 2 1.0.0\n")
  end

  it "has no 0.1.x converter API" do
    out, err, status = run_ruby(root, <<~RUBY)
      names = %i[Tokenizer Aggregator Converter Equation Symbol XML Constants]
      puts Latexmath.respond_to?(:legacy_parse)
      puts names.select { |n| Latexmath.const_defined?(n, false) }.inspect
    RUBY
    expect(status).to be_success, err
    expect(out).to eq("false\n[]\n")
  end

  it "raises ParseError with offsets into the caller's input" do
    out, err, status = run_ruby(root, <<~RUBY)
      begin
        Latexmath.parse("é}", engine: :ruby)
      rescue Latexmath::ParseError => e
        puts [e.class.ancestors.include?(Latexmath::Error), e.char_offset, e.byte_offset].inspect
      end
    RUBY
    expect(status).to be_success, err
    expect(out).to eq("[true, 1, 2]\n")
  end
end
