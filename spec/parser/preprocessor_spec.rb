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
end
