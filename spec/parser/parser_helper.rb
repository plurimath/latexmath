# frozen_string_literal: true

require "json"
require "yaml"
require "latexmath/parser"
require "latexmath/model"
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

  # A model instance as plain data: Symbol keys, the non-nil attributes in
  # declared order. A MathSymbol is its spelling, as the grammar bound it.
  def model_data(value)
    case value
    when Array then value.map { |v| model_data(v) }
    when Lutaml::Model::Serializable
      # Derived attributes (MathSymbol's value and kind) are computed from
      # the bound spelling, so they are not part of the bound data.
      value.class.attributes.each_with_object({}) do |(name, attribute), h|
        next if attribute.derived?

        v = value.public_send(name)
        h[name] = model_data(v) unless v.nil?
      end
    else value
    end
  end

  # Bound or model data in comparable form: string keys sorted, text as
  # String.
  def plain(value)
    case value
    when Hash then value.map { |k, v| [k.to_s, plain(v)] }.sort_by(&:first).to_h
    when Array then value.map { |v| plain(v) }
    when nil then nil
    else value.to_s
    end
  end

  # Expects Latexmath.parse to build the typed model from +result+'s model
  # binding without loss: the model, as data, is the bound data, and
  # unwrapping it gives the legacy tree's text.
  def expect_model(result, input, decimal, engine)
    document = Latexmath.parse(input, decimal: decimal, engine: engine)
    expect(document).to be_a(Latexmath::Model::Document)
    expect(document.decimal).to eq(decimal)
    data = model_data(document.expression)
    expect(plain(data)).to eq(plain(result.model))
    legacy = Latexmath::RawParser.restore_capture_names(Latexmath::Unwrap.call(data))
    expect(plain(legacy)).to eq(plain(result.tree))
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
