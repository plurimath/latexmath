# frozen_string_literal: true

require_relative "parser_helper"

RSpec.describe Latexmath::Preprocessor do
  def pre(input) = described_class.call(input)

  it "encodes non-ASCII and markup characters as hexadecimal entities" do
    expect(pre("a<b>c\"d'é")).to eq("a&#x3c;b&#x3e;c\"d&#x27;&#xe9;")
  end

  it "decodes entities before encoding them again" do
    expect(pre("&alpha;&amp;&#945;")).to eq("&#x3b1;&&#x3b1;")
  end

  it "removes spaces that do not follow a backslash, and newlines" do
    expect(pre("a + b\\ c\n\nd")).to eq("a+b\\ cd")
  end

  it "turns a row break followed by a space into a plain row break" do
    expect(pre("a \\\\ b")).to eq("a\\\\b")
  end

  it "turns a backslash before a newline into an escaped space" do
    expect(pre("a\\\nb")).to eq("a\\ b")
    expect(pre("a\\\\\nb")).to eq("a\\\\ b")
    expect(pre("a\\\\\\\nb")).to eq("a\\\\\\b")
  end

  it "puts \\text and \\mbox groups back as written" do
    expect(pre("a < b \\\\ c\n\\text{é x} é")).to eq("a&#x3c;b\\\\c\\text{é x}&#xe9;")
    expect(pre("\\mbox{a  b}+1")).to eq("\\mbox{a  b}+1")
  end

  describe "\\text and \\mbox group search" do
    legacy = %r(\\(?:mbox|text)\{[^}]+\})
    alphabet = ["\\mbox{", "\\text{", "\\textbf{", "\\", "{", "}", "}}", "a", " ", "\n", "é", "mbox", "x{"].freeze

    it "finds the matches of the legacy regexp on random input" do
      rng = Random.new(541)
      500.times do
        input = Array.new(rng.rand(0..24)) { alphabet[rng.rand(alphabet.size)] }.join
        found = described_class.text_groups(input).map { |range| input[range] }
        expect(found).to eq(input.scan(legacy)), input.inspect
        expected = legacy_call(input, legacy)
        actual = pre(input)
        expect([actual, actual.encoding]).to eq([expected, expected.encoding]), input.inspect
      end
    end

    it "stays linear on many unclosed openers" do
      input = "\\mbox{" * 20_000
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect(described_class.text_groups(input)).to eq([])
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 1.0
    end

    def legacy_call(input, legacy)
      groups = input.scan(legacy)
      text = described_class::ENTITIES.encode(described_class::ENTITIES.decode(input), :hexadecimal)
      text = described_class.gsub_space_and_unicodes(text)
      text.gsub(legacy) { |_str| groups.shift }
    end
  end
end
