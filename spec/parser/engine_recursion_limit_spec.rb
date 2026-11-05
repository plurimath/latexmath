# frozen_string_literal: true

require_relative "parser_helper"

RSpec.describe "Latexmath native recursion limit" do
  before do
    skip "native extension unavailable" unless Parsanol::Native.available?
    allow(Parsanol::Native).to receive(:parse)
      .and_raise(Parsanol::RecursionLimitExceeded,
                 "Recursion limit exceeded: depth 1001 exceeds limit of 1000")
  end

  it "reruns on the Ruby engine under engine: :auto" do
    Latexmath.parse("x", engine: :auto)
    expect(Latexmath.last_engine).to eq(:ruby)
  end

  it "raises NestingTooDeep under engine: :native" do
    expect { Latexmath.parse("x", engine: :native) }
      .to raise_error(Latexmath::NestingTooDeep, /recursion limit/)
  end

  it "leaves engine: :ruby untouched" do
    Latexmath.parse("x", engine: :ruby)
    expect(Latexmath.last_engine).to eq(:ruby)
  end
end
