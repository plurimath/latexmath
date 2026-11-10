# frozen_string_literal: true

require "json"

RSpec.describe "portable symbol declarations" do
  it "keeps direct construction, live spelling and writer values" do
    symbol = Latexmath::Model::MathSymbol.new(spelling: "alpha")
    defaults = [symbol.using_default?(:value), symbol.using_default?(:kind)]
    expect([symbol.value, symbol.kind]).to eq(["α", "symbol"])
    expect([symbol.using_default?(:value), symbol.using_default?(:kind)]).to eq(defaults)
    expect(JSON.parse(symbol.to_json)).to eq("spelling" => "alpha", "value" => "α", "kind" => "symbol")
    symbol.spelling.replace("unlisted")
    expect([symbol.value, symbol.kind]).to eq(["unlisted", "unlisted"])
    symbol.spelling = nil
    expect([symbol.value, symbol.kind]).to eq([nil, nil])
  end

  it "keeps the derived getter when a resolved slot was supplied" do
    symbol = Latexmath::Model::MathSymbol.new(spelling: "alpha", value: "wrong", kind: "wrong")
    expect([symbol.value, symbol.kind]).to eq(["α", "symbol"])
    expect(Latexmath::Model::MathSymbol.attributes[:value].options).not_to have_key(:method_name)
  end
end
