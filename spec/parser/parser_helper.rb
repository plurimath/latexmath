# frozen_string_literal: true

require "json"
require "yaml"
require "latexmath/parser"
require_relative "../../scripts/oracle/lib/latexmath_oracle/tagged"

module ParserSpecHelpers
  ROOT = File.expand_path("../..", __dir__)
  SAMPLE = File.join(__dir__, "fixtures", "oracle-sample.yaml")

  # The decimal marker Plurimath.configuration.decimal gives for each locale
  # an oracle inventory uses (Plurimath::Formatter::SupportedLocales at the
  # pinned commit), so a row's locale selects the same grammar entry here.
  LOCALE_DECIMALS = { nil => ".", "en" => ".", "fr" => ",", "de" => ",", "ar" => "٫" }.freeze

  # The legacy capture's tagged form (scripts/oracle), so that a tree here
  # compares with a captured one by keys, key order, key kinds, slice text
  # and offsets.
  def tagged(value, source: nil)
    LatexmathOracle::Tagged.dump(value, source: source)
  end

  def native_required?
    ENV["LATEXMATH_REQUIRE_NATIVE"] == "1"
  end

  def native_or_skip
    skip "native engine not available" unless Latexmath::Engine.native_available? || native_required?
  end
end

RSpec.configure do |config|
  config.include ParserSpecHelpers
end
