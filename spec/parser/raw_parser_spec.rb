# frozen_string_literal: true

require_relative "parser_helper"

RSpec.describe Latexmath::RawParser do
  def parse(input, **opts)
    described_class.parse(input, engine: :ruby, **opts)
  end

  def slices(tree)
    found = []
    walk = lambda do |node|
      case node
      when Hash then node.each_value(&walk)
      when Array then node.each(&walk)
      when Parsanol::Slice then found << [node.to_s, node.offset]
      end
    end
    walk.call(tree)
    found
  end

  it "returns the legacy tree for a fraction" do
    result = parse("\\frac{1}{2}")
    expect(result.text).to eq("\\frac{1}{2}")
    expect(result.tree.keys).to eq(%i[binary])
    expect(result.tree.dig(:binary, :binary).to_s).to eq("frac")
    expect(result.tree.dig(:binary, :binary)).to be_a(Parsanol::Slice)
  end

  it "keeps slice offsets in the preprocessed text" do
    expect(slices(parse("é + b").tree)).to include(["+", 6], ["b", 7])
  end

  it "restores the legacy String key of a matrix row break" do
    tree = parse("\\begin{matrix}a & b \\\\ c & d\\end{matrix}").tree
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
    expect(keys).not_to include(:row_break)
  end

  it "selects the grammar entry by decimal marker" do
    expect(slices(parse("1.5").tree)).to eq([["1.5", 0]])
    expect(slices(parse("1,5", decimal: ",").tree)).to eq([["1,5", 0]])
    expect(slices(parse("1,5").tree)).not_to eq([["1,5", 0]])
    expect(slices(parse("1٫5", decimal: "٫").tree)).to eq([["1&#x66b;5", 0]])
  end

  it "does not load Plurimath" do
    parse("a")
    expect($LOADED_FEATURES.grep(%r{/plurimath[/.]})).to be_empty
    expect(defined?(Plurimath)).to be_nil
  end

  describe "arguments" do
    it "rejects non-String input" do
      expect { parse(12) }.to raise_error(ArgumentError, /must be a String/)
    end

    it "rejects invalid UTF-8" do
      expect { parse("a\xFF".dup.force_encoding("UTF-8")) }.to raise_error(ArgumentError, /not valid UTF-8/)
    end

    it "transcodes other encodings" do
      expect(parse("\xE9".dup.force_encoding("ISO-8859-1")).text).to eq("&#xe9;")
    end

    it "rejects an unsupported decimal marker" do
      expect { parse("1", decimal: ";") }.to raise_error(ArgumentError, /unsupported decimal marker/)
    end

    it "rejects an unknown engine" do
      expect { described_class.parse("a", engine: :fast) }.to raise_error(ArgumentError, /unknown engine/)
    end
  end

  describe "refusals" do
    it "raises ParseError with offsets into the preprocessed text" do
      expect { parse("\\frac{1}{") }.to raise_error(Latexmath::ParseError) { |e|
        expect(e).not_to be_a(Latexmath::NestingTooDeep)
        expect(e.input).to eq("\\frac{1}{")
        expect([e.char_offset, e.byte_offset]).to eq([9, 9])
      }
    end

    it "counts characters and bytes apart after non-ASCII text" do
      expect { parse("\\text{é}}") }.to raise_error(Latexmath::ParseError) { |e|
        expect(e.input).to eq("\\text{é}}")
        expect(e.byte_offset - e.char_offset).to eq(1)
      }
    end
  end

  describe "engines" do
    it "records the engine that ran" do
      parse("a")
      expect(Latexmath.last_engine).to eq(:ruby)
    end

    it "raises EngineUnavailable for :native without the extension" do
      allow(Latexmath::Engine).to receive(:native_available?).and_return(false)
      expect { described_class.parse("a", engine: :native) }.to raise_error(Latexmath::EngineUnavailable)
    end

    it "uses Ruby under :auto without the extension" do
      allow(Latexmath::Engine).to receive(:native_available?).and_return(false)
      expect(described_class.parse("a", engine: :auto).engine).to eq(:ruby)
    end

    it "gives the same tree on the native engine" do
      native_or_skip
      input = "\\sum_{i=1}^{n} \\frac{x_i}{\\sqrt[3]{y}} \\begin{pmatrix}1 & 2 \\\\ 3 & 4\\end{pmatrix}"
      ruby = parse(input)
      native = described_class.parse(input, engine: :native)
      expect(native.engine).to eq(:native)
      expect(tagged(native.tree, source: native.text)).to eq(tagged(ruby.tree, source: ruby.text))
    end

    it "refuses deep input on native off the main thread, and reruns it on Ruby under :auto" do
      native_or_skip
      deep = "#{'{' * 30}a#{'}' * 30}"
      Thread.new do
        expect { described_class.parse(deep, engine: :native) }.to raise_error(Latexmath::NestingTooDeep)
        expect(Latexmath.last_engine).to eq(:native)
        expect(described_class.parse(deep, engine: :auto).engine).to eq(:ruby)
      end.join
    end

    it "turns an exhausted Ruby stack into NestingTooDeep" do
      deep = "#{'{' * 2000}a#{'}' * 2000}"
      expect { parse(deep) }.to raise_error(Latexmath::NestingTooDeep) { |e|
        expect([e.byte_offset, e.char_offset]).to eq([nil, nil])
      }
    end
  end

  describe "the declared bindings" do
    it "carry the parse shape's tree unchanged" do
      loaded = Latexmath.artifacts
      shape = loaded.parse.root_atom("dot").parse("x^2")
      bound = loaded.bindings.apply("dot", shape)
      expect(bound.keys).to eq([:latex_tree])
      expect(bound[:latex_tree]).to equal(shape[:latex_tree])
      expect(tagged(parse("x^2").tree)).to eq(tagged(shape[:latex_tree]))
    end
  end
end
