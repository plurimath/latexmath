# frozen_string_literal: true

require_relative "../../scripts/oracle/lib/latexmath_oracle/tagged"

module FakeParser
  # Shaped like Parsanol::Slice / Parslet::Slice: text plus character offset.
  class Slice
    attr_reader :offset

    def initialize(text, offset)
      @text = text
      @offset = offset
    end

    def to_s
      @text
    end
  end
end

RSpec.describe LatexmathOracle::Tagged do
  def dump(value, **options)
    described_class.dump(value, **options)
  end

  it "keeps hash versus array and symbol versus string keys" do
    expect(dump({ a: [] })).to eq(
      "t" => "hash", "entries" => [[{ "t" => "sym", "v" => "a" }, { "t" => "array", "items" => [] }]]
    )
    expect(dump({ "a" => "" })["entries"].first)
      .to eq([{ "t" => "str", "v" => "a" }, { "t" => "str", "v" => "" }])
  end

  it "keeps key insertion order and nil values" do
    entries = dump({ b: nil, a: 1 })["entries"]
    expect(entries.map { |key, _| key["v"] }).to eq(%w[b a])
    expect(entries.first.last).to eq("t" => "nil")
  end

  it "distinguishes a missing key from a nil value" do
    expect(dump({})).not_to eq(dump({ a: nil }))
  end

  it "keeps numbers as their spelling" do
    expect(dump(10)).to eq("t" => "int", "v" => "10")
    expect(dump(1.50)).to eq("t" => "float", "v" => "1.5")
    expect(dump("1.50")).to eq("t" => "str", "v" => "1.50")
  end

  it "records slice text with character and byte offsets" do
    source = "é+x"
    node = dump({ symbol: FakeParser::Slice.new("x", 2) }, source: source)["entries"].first.last
    expect(node).to eq("t" => "slice", "v" => "x", "char_offset" => 2, "byte_offset" => 3)
  end

  it "keeps invalid UTF-8 as bytes" do
    expect(dump("\xFF".b)).to eq("t" => "bytes", "hex" => "ff", "enc" => "ASCII-8BIT")
  end

  it "records objects by class and instance variables in order" do
    klass = Struct.new(:unused) do
      def initialize(*)
        super
        @second = :b
        @first = "a"
      end
    end
    stub_const("FakeModel", klass)
    node = dump(FakeModel.new)
    expect(node["class"]).to eq("FakeModel")
    expect(node["ivars"].map(&:first)).to eq(%w[@second @first])
  end

  it "marks cycles instead of recursing" do
    list = []
    list << list
    expect(dump(list)).to eq("t" => "array", "items" => [{ "t" => "cycle", "class" => "Array" }])
  end

  it "dumps a shared child every time it appears" do
    shared = [1]
    expect(dump([shared, shared])["items"].uniq.size).to eq(1)
    expect(dump([shared, shared])["items"].size).to eq(2)
  end
end
