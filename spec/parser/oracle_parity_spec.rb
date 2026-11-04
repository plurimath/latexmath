# frozen_string_literal: true

require_relative "parser_helper"

# Replays a legacy oracle capture report (scripts/oracle/capture.rb against
# Plurimath at the pinned commit) through the internal raw-tree boundary.
# For every row it requires the same preprocessed text and the same raw tree
# in the capture's tagged form (keys, key order and kinds, slice text and
# byte and character offsets) once the grammar's shape-normalization
# wrappers are unwrapped (Latexmath::Unwrap), or, for a grammar refusal, a
# ParseError at the same byte and character position. For every parsed row
# it also requires Latexmath.parse to build the typed model losslessly.
#
#   LATEXMATH_ORACLE_REPORT     the capture report (required; without it the
#                               replay is skipped)
#   LATEXMATH_ORACLE_INVENTORY  the inventory it was captured from (default:
#                               fixtures/oracle-sample.yaml)
#   LATEXMATH_ORACLE_ENGINES    engines to replay on (default "ruby,native")
#
# CI captures the sample on every pull request and the pinned testsuite rows
# in the replay workflow.
RSpec.describe "raw-tree parity with the legacy oracle" do
  report_path = ENV.fetch("LATEXMATH_ORACLE_REPORT", nil)
  inventory_path = ENV.fetch("LATEXMATH_ORACLE_INVENTORY", ParserSpecHelpers::SAMPLE)
  engines = ENV.fetch("LATEXMATH_ORACLE_ENGINES", "ruby,native").split(",").map(&:to_sym)
  inventory = YAML.safe_load_file(inventory_path).fetch("rows")

  if report_path.nil?
    it "replays a capture report" do
      skip "LATEXMATH_ORACLE_REPORT is not set"
    end
    next
  end

  report = JSON.parse(File.read(report_path), max_nesting: false)
  rows = report.fetch("rows").to_h { |row| [row.fetch("id"), row] }

  it "has a complete report for exactly the inventory rows" do
    ids = inventory.map { |r| r.fetch("id") }
    expect(ids.uniq.size).to eq(ids.size)
    expect(report["complete"]).to be(true)
    expect(report.dig("oracle", "plurimath_commit"))
      .to eq(YAML.safe_load_file(File.join(ParserSpecHelpers::ROOT, "scripts/oracle/pins.yml")).dig("plurimath", "commit"))
    expect(rows.keys.sort).to eq(ids.sort)
    expect(rows.values.map { |r| r["status"] }.uniq - %w[succeeded refused]).to be_empty
  end

  inventory.each do |item|
    id = item.fetch("id")
    engines.each do |engine|
      it "reproduces #{id} on the #{engine} engine" do
        native_or_skip if engine == :native
        capture = rows.fetch(id).fetch("capture")
        input = item.fetch("input")
        expect(tagged(input)).to eq(capture["input"])
        decimal = ParserSpecHelpers::LOCALE_DECIMALS.fetch(item.dig("configuration", "locale"))
        expect_parity(capture, input, decimal, engine)
      end
    end
  end

  def expect_parity(capture, input, decimal, engine)
    pre = capture.fetch("preprocessed")
    raise "legacy preprocessing failed: #{pre['error'].inspect}" unless pre.key?("ok")

    raw = capture.fetch("raw_tree")
    if raw.key?("ok")
      result = Latexmath::RawParser.parse(input, decimal: decimal, engine: engine)
      expect(tagged(result.text)).to eq(pre["ok"])
      expect(tagged(result.tree, source: result.text)).to eq(raw["ok"])
      expect(result.engine).to eq(engine)
      expect_model(result, input, decimal, engine)
    else
      error = raw.fetch("error")
      expect(error["class"]).to eq("Parsanol::ParseFailed")
      expect { Latexmath::RawParser.parse(input, decimal: decimal, engine: engine) }
        .to raise_error(Latexmath::ParseError) { |e|
          expect(e).not_to be_a(Latexmath::NestingTooDeep)
          expect(e.grammar_input).to eq(pre.dig("ok", "v"))
          expect(e.grammar_input.encoding).to eq(Encoding::UTF_8)
          # scripts/oracle/latex_worker.rb records Parsanol's failure
          # position (Parsanol::Cause#pos, a byte offset) and the character
          # offset it falls at.
          expect([e.grammar_byte_offset, e.grammar_char_offset])
            .to eq([error.fetch("byte_offset"), error.fetch("char_offset")])
          # The public position is in the caller's text.
          expect(e.input).to eq(input)
          expect(e.char_offset).to be_between(0, input.length)
          expect(e.input.byteslice(0, e.byte_offset).length).to eq(e.char_offset)
        }
    end
  end
end
