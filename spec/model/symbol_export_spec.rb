# frozen_string_literal: true

require "json"
require_relative "../parser/parser_helper"

RSpec.describe "MathSymbol value and kind" do
  let(:lml) { JSON.parse(File.read(File.expand_path("../../model/latex.lml.json", __dir__), encoding: "UTF-8")) }

  it "declares value and kind in the LML export" do
    symbol = lml.fetch("models").find { |m| m["model"] == "Latexmath::Model::MathSymbol" }
    expect(symbol.to_json).to include('"value"', '"kind"')
  end

  [%w[\\alpha alpha], %w[( (], %w[\\rangle rangle]].each do |input, spelling|
    it "stores the catalog value and kind for #{spelling}" do
      doc = Latexmath.parse(input, engine: :ruby)
      symbols = []
      stack = [doc]
      until stack.empty?
        node = stack.pop
        symbols << node if node.is_a?(Latexmath::Model::MathSymbol)
        node.class.attributes.each_key do |name|
          Array(node.public_send(name)).each { |c| stack << c if c.is_a?(Lutaml::Model::Serializable) }
        end
      end
      symbol = symbols.find { |s| s.spelling.strip == spelling }
      entry = Latexmath::Symbols.lookup(spelling)
      expect(entry).not_to be_nil
      expect([symbol.value, symbol.kind]).to eq([entry.value, entry.kind])
      expect(doc.to_json).to include(%("kind":"#{entry.kind}"))
      expect(Latexmath::Model::Document.from_json(doc.to_json)).to eq(doc)
    end
  end
end
