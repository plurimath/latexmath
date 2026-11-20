# frozen_string_literal: true

require_relative "../parser/parser_helper"

RSpec.describe "boxed expressions" do
  %i[ruby native].each do |engine|
    context "on #{engine}" do
      before { native_or_skip if engine == :native }

      it "retains the box command and its grouped contents in the typed model" do
        document = Latexmath.parse("\\boxed{x + 1}", engine: engine)
        box = document.expression.unary_functions
        expect(box).to be_a(Latexmath::Model::UnaryFunctions)
        expect(box.unary).to eq("boxed")
        expect(model_data(box.first_value))
          .to eq(model_data(Latexmath.parse("{x + 1}", engine: engine).expression))
      end

      it "preserves nested boxes and fractions" do
        input = "\\boxed{\\frac{1}{\\boxed{x}}}"
        result = Latexmath::RawParser.parse(input, engine: engine)
        expect_model(result, input, ".", engine)
        expect(result.tree.dig(:unary_functions, :unary).to_s).to eq("boxed")
        expect(model_data(Latexmath.parse(input, engine: engine).expression).to_s.scan("boxed").size).to eq(2)
      end

      it "uses the caller's decimal marker inside the box" do
        [".", ",", "٫"].each do |decimal|
          input = "\\boxed{1#{decimal}5}"
          result = Latexmath::RawParser.parse(input, engine: engine, decimal: decimal)
          expect_model(result, input, decimal, engine)
          expect(result.tree.to_s).to include(decimal == "٫" ? "1&#x66b;5" : "1#{decimal}5")
        end
      end

      it "requires a braced argument and the complete command name" do
        ["\\boxed", "\\boxed x", "\\boxed{x", "\\boxedx{x}"].each do |input|
          expect { Latexmath.parse(input, engine: engine) }.to raise_error(Latexmath::ParseError)
        end
      end

      it "retains an empty box rather than dropping the command" do
        result = Latexmath::RawParser.parse("\\boxed{}", engine: engine)
        expect(result.tree.dig(:unary_functions, :unary).to_s).to eq("boxed")
        expect(result.tree[:unary_functions]).to have_key(:first_value)
        expect(result.tree.dig(:unary_functions, :first_value))
          .to eq(Latexmath::RawParser.parse("{}", engine: engine).tree)
        expect_model(result, "\\boxed{}", ".", engine)
      end
    end
  end
end
