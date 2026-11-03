# frozen_string_literal: true

require_relative "parser_helper"

RSpec.describe Latexmath::Symbols do
  let(:data) { JSON.parse(File.read(described_class::DATA_PATH, encoding: "UTF-8")) }

  it "loads the exported table with its provenance" do
    expect(data["format"]).to eq("latexmath-symbols/v1")
    pins = YAML.safe_load_file(File.join(ParserSpecHelpers::ROOT, "scripts/oracle/pins.yml"))
    expect(described_class.provenance["commit"]).to eq(pins.dig("plurimath", "commit"))
    expect(described_class.size).to eq(data["symbols"].size)
    expect(data.dig("counts", "spellings")).to eq(data["symbols"].size)
    expect(data["symbols"].map { |r| r["spelling"].b }).to eq(data["symbols"].map { |r| r["spelling"].b }.sort)
  end

  it "resolves command names, entities and parens without Plurimath" do
    expect(described_class.lookup("alpha").to_h)
      .to eq(spelling: "alpha", value: "α", mathml: "mi", kind: "symbol", plurimath_class: "Alpha")
    expect(described_class.lookup("&#x3b1;").value).to eq("α")
    expect(described_class.lookup("rightarrow").to_h.values_at(:value, :mathml)).to eq(["→", "mo"])
    expect(described_class.lookup("(").to_h.values_at(:kind, :plurimath_class)).to eq(["open", "Paren::Lround"])
    expect(described_class.lookup(" alpha ")).to eq(described_class.lookup("alpha"))
    expect(defined?(Plurimath)).to be_nil
  end

  it "keeps text the table lacks as a plain symbol of that text" do
    expect(described_class.lookup("x")).to be_nil
    expect(described_class.resolve(" x ").to_h)
      .to eq(spelling: "x", value: "x", mathml: nil, kind: "symbol", plurimath_class: "Symbol")
  end

  it "has a kind, a value and a MathML element for every spelling" do
    expect(data["symbols"].map { |r| r["kind"] }.uniq - %w[symbol open close paren]).to be_empty
    expect(data["symbols"].map { |r| r["mathml"] }.uniq - %w[mi mo]).to be_empty
    expect(data["symbols"].count { |r| r["value"].to_s.empty? }).to eq(0)
  end
end
