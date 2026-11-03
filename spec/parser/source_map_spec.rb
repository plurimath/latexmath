# frozen_string_literal: true

require_relative "parser_helper"

RSpec.describe Latexmath::SourceMap do
  def origins(input)
    text, map = described_class.call(input)
    expect(text.b).to eq(Latexmath::Preprocessor.call(input).b)
    expect(map.size).to eq(text.length + 1)
    expect(map.last).to eq(input.length)
    [text, map]
  end

  let(:pieces) do
    ["\\", "{", "}", " ", "\n", "&", "#", "x", ";", "é", "a", "\\text{", "\\mbox{", "&amp;",
     "&#x41;", "&#65;", "&alpha;", "\"", "<", "'", "\u0661", "\\\\ ", "&#xa;", "\\\\\n", "𝑥"]
  end

  it "writes exactly the preprocessed text for random input" do
    rng = Random.new(541)
    3000.times do
      input = Array.new(rng.rand(1..16)) { pieces.sample(random: rng) }.join
      origins(input)
    end
  end

  it "writes exactly the preprocessed text for the oracle sample rows" do
    YAML.safe_load_file(ParserSpecHelpers::SAMPLE).fetch("rows").each do |row|
      origins(row.fetch("input"))
    end
  end

  it "maps an encoded character to the caller character it encodes" do
    text, map = origins("é+x")
    expect(text).to eq("&#xe9;+x")
    expect(map.first(7)).to eq([0, 0, 0, 0, 0, 0, 1])
    expect(map[text.rindex("x")]).to eq(2)
  end

  it "maps a decoded entity to the start of the entity" do
    text, map = origins("a&amp;b")
    expect(text).to eq("a&b")
    expect(map).to eq([0, 1, 6, 7])
  end

  it "skips removed spaces and newlines" do
    text, map = origins("a b\n\nc")
    expect(text).to eq("abc")
    expect(map).to eq([0, 2, 5, 6])
  end

  it "maps a restored \\text group character for character" do
    input = "é\\text{é ü}x"
    text, map = origins(input)
    group = text.index("\\text{")
    expect(text[group..]).to eq("\\text{é ü}x")
    expect(map[group, 11]).to eq((1..11).to_a)
  end

  it "gives the caller character of a preprocessed position" do
    input = "é + \\frac{1}{"
    text = Latexmath::Preprocessor.call(input)
    expect(described_class.caller_char(input, text, text.length)).to eq(input.length)
    expect(described_class.caller_char(input, text, text.index("\\"))).to eq(input.index("\\"))
  end

  it "maps nothing when the text is not the preprocessed text of the input" do
    expect(described_class.caller_char("a b", "a b", 1)).to be_nil
  end
end
