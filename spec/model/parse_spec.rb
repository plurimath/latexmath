# frozen_string_literal: true

require_relative "../parser/parser_helper"

RSpec.describe "Latexmath.parse" do
  def parse(input, **opts)
    Latexmath.parse(input, engine: :ruby, **opts)
  end

  it "returns the typed Document built from the grammar's model binding" do
    document = parse("\\frac{1}{2}")
    expect(document).to be_a(Latexmath::Model::Document)
    expect(document.decimal).to eq(".")
    binary = document.expression.binary
    expect(binary).to be_a(Latexmath::Model::Binary)
    expect(binary.binary.literal).to eq("frac")
    expect(binary.first_value.expression.number).to eq("1")
    expect(binary.second_value.expression.number).to eq("2")
  end

  it "gives a symbol its spelling, Unicode value and kind from the symbol table" do
    symbol = parse("\\alpha").expression.symbols
    expect(symbol).to be_a(Latexmath::Model::MathSymbol)
    expect([symbol.spelling, symbol.value, symbol.kind]).to eq(%w[alpha α symbol])
  end

  it "keeps numbers as written, with the decimal marker of the entry" do
    expect(parse("1,5", decimal: ",").expression.number).to eq("1,5")
    expect(parse("1,5", decimal: ",").decimal).to eq(",")
  end

  it "returns an empty Document for input without a formula" do
    ["", "  ", "\n"].each do |input|
      document = parse(input)
      expect(document).to be_a(Latexmath::Model::Document)
      expect(document.expression).to be_nil
    end
  end

  it "builds the same model on the native engine" do
    native_or_skip
    input = "\\sum_{i=1}^{n} \\alpha_i \\over \\sqrt{x}"
    expect(model_data(Latexmath.parse(input, engine: :native).expression))
      .to eq(model_data(parse(input).expression))
  end

  it "builds every class from plain data, with no cast hook or walker" do
    result = Latexmath::RawParser.parse("\\left( a \\right) \\text{b}", engine: :ruby)
    expect(plain(model_data(parse("\\left( a \\right) \\text{b}").expression))).to eq(plain(result.model))
  end

  it "reports refusals with offsets in the caller's text" do
    expect { parse("é + (}") }.to raise_error(Latexmath::ParseError) { |e|
      expect(e).not_to be_a(Latexmath::NestingTooDeep)
      expect(e.input).to eq("é + (}")
      expect(e.input.byteslice(0, e.byte_offset).length).to eq(e.char_offset)
      expect(e.grammar_input).to start_with("&#xe9;")
    }
  end

  it "keeps the legacy US-ASCII preprocessing result at the raw boundary" do
    expect(Latexmath::RawParser.parse("a + b", engine: :ruby).text.encoding).to eq(Encoding::US_ASCII)
  end

  describe "the cases environment" do
    let(:input) { "f(x)=\\begin{cases}1 & x>0\\\\0 & \\text{otherwise}\\end{cases}" }

    it "is read like the other environments" do
      expect { parse(input) }.not_to raise_error
      environment = parse("\\begin{cases}1 & x\\end{cases}").expression.environment
      expect(environment.environment.literal).to eq("cases")
      expect(environment.ending.environment.literal).to eq("cases")
      expect(environment.table_data).to be_a(Latexmath::Model::TableData)
    end

    it "keeps the column and row separators in the body" do
      tree = Latexmath::RawParser.parse(input, engine: :ruby).tree
      keys = []
      walk = lambda do |node|
        case node
        when Hash
          keys.concat(node.keys)
          node.each_value(&walk)
        when Array then node.each(&walk)
        end
      end
      walk.call(tree)
      expect(keys).to include("\\\\")
      expect(tree.to_s).to include("cases")
    end
  end

  it "rejects bad arguments" do
    expect { parse(1) }.to raise_error(ArgumentError, /must be a String/)
    expect { parse("1", decimal: ";") }.to raise_error(ArgumentError, /unsupported decimal marker/)
  end

  describe "the generated model" do
    let(:wrappers) { Latexmath::Unwrap.wrappers }

    it "declares no union and one kind per capture" do
      Latexmath::Model.constants.map { |c| Latexmath::Model.const_get(c) }
                      .select { |k| k.is_a?(Class) && k < Lutaml::Model::Serializable }
                      .each do |klass|
        klass.attributes.each_value do |attribute|
          expect(attribute.type).not_to be_a(Lutaml::Model::Type::Union) if defined?(Lutaml::Model::Type::Union)
        end
      end
    end

    it "unwraps the empty text of \\text{} to the legacy empty list" do
      result = Latexmath::RawParser.parse("\\text{}", engine: :ruby)
      expect(result.raw.dig(:first_value, :text_list).to_s).to eq("")
      expect(result.tree[:first_value]).to eq([])
    end

    it "unwraps an absent named option to the legacy nil" do
      result = Latexmath::RawParser.parse("\\mathrm{}", engine: :ruby)
      expect(result.raw.dig(:intermediate_exp, :expression)).to have_key(:absent)
      expect(result.tree.dig(:intermediate_exp, :expression)).to be_nil
    end

    it "lists every wrapper with its unwrap kind" do
      expect(wrappers).to include("literal" => "text", "spelling" => "text_list", "absent" => "nil", "items" => "items")
    end
  end
end
