# frozen_string_literal: true

require "digest"
require "open3"
require "tmpdir"
require "yaml"
require_relative "../parser/parser_helper"
require_relative "../../scripts/stage_cases"

module StageCasesSpecSupport
  # Shaped like Parsanol::Slice: text plus byte offset.
  Slice = Struct.new(:text, :offset) do
    def self.name
      "StageCasesSpecSupport::Slice"
    end

    def to_s
      text
    end
  end
end

RSpec.describe LatexmathStageCases do

  describe LatexmathStageCases::Canonical do
    def dump(value, source: nil)
      described_class.dump(value, source: source)
    end

    it "writes valid UTF-8 text as str without an encoding label" do
      ascii = "x^2".encode(Encoding::US_ASCII)
      expect(dump(ascii)).to eq("str" => "x^2")
      expect(dump("é")).to eq("str" => "é")
    end

    it "keeps text that is not valid UTF-8 as hex bytes with its encoding" do
      expect(dump("\xFF".b)).to eq("bytes" => "ff", "encoding" => "ASCII-8BIT")
    end

    it "keeps hash order, symbol and string keys, nil and arrays" do
      value = { b: [nil, "x"], "a" => 1 }
      expect(dump(value)).to eq(
        "hash" => [
          [{ "sym" => "b" }, { "array" => [{ "nil" => true }, { "str" => "x" }] }],
          [{ "str" => "a" }, { "int" => "1" }],
        ],
      )
    end

    it "writes a slice with its byte and character offsets in the grammar input" do
      expect(dump(StageCasesSpecSupport::Slice.new("b", 3), source: "éab")).to eq("slice" => "b", "byte_offset" => 3, "char_offset" => 2)
    end

    it "refuses a value it has no tag for" do
      expect { dump(1.5r) }.to raise_error(LatexmathStageCases::Error, /Rational/)
    end
  end

  # A one-generation testsuite checkout with a two-row latex payload.
  def build_testsuite(dir, cases)
    gen = File.join(dir, "stages/latex/generations/000001")
    FileUtils.mkdir_p(File.join(gen, "payloads"))
    payload = { "schema" => "plurimath-corpus/latex/1", "group" => "sample", "cases" => cases }
    File.write(File.join(gen, "payloads/sample.yaml"), YAML.dump(payload))
    provenance = { "schema" => "plurimath-stage/provenance/1", "language" => "latex", "generation" => 1,
                   "payloads" => [{ "path" => "payloads/sample.yaml" }] }
    File.write(File.join(gen, "provenance.yaml"), YAML.dump(provenance))
    digest = LatexmathStageCases::Source.snapshot_digest(gen)
    FileUtils.mkdir_p(File.join(dir, "generations"))
    ledger = { "schema" => "plurimath-stage/ledger/1", "language" => "latex", "layout" => 1,
               "entries" => [{ "generation" => 1, "path" => "stages/latex/generations/000001",
                               "snapshot_digest" => digest }] }
    File.write(File.join(dir, "generations/latex.yaml"), YAML.dump(ledger))
    system("git", "-C", dir, "init", "-q", exception: true)
    system("git", "-C", dir, "-c", "user.name=t", "-c", "user.email=t@example.com", "add", ".", exception: true)
    system("git", "-C", dir, "-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-qm", "t",
           exception: true)
    digest
  end

  let(:cases) do
    [
      { "id" => "latex-frac-simple", "input" => "\\frac{1}{2}", "input_format" => "latex",
        "preprocessed" => "\\frac{1}{2}",
        "parse_tree" => { "binary" => { "binary" => "frac", "first_value" => { "expression" => { "number" => "1" } },
                                        "second_value" => { "expression" => { "number" => "2" } } } } },
      { "id" => "latex-stray-close-brace", "input" => "x}", "input_format" => "latex", "preprocessed" => "x}",
        "error" => { "category" => "parse_error", "index" => 1 } },
    ]
  end

  describe LatexmathStageCases::Source do
    it "verifies the snapshot digest against the ledger and the expected digest" do
      Dir.mktmpdir do |dir|
        digest = build_testsuite(dir, cases)
        _entry, _gen, payloads = described_class.verify(dir, "latex", 1, digest)
        expect(payloads).to eq(["payloads/sample.yaml"])

        expect { described_class.verify(dir, "latex", 1, "sha256:#{'0' * 64}") }
          .to raise_error(LatexmathStageCases::Error, /not the expected/)
        File.write(File.join(dir, "stages/latex/generations/000001/payloads/sample.yaml"), "tampered\n", mode: "a")
        expect { described_class.verify(dir, "latex", 1, digest) }
          .to raise_error(LatexmathStageCases::Error, /does not match the ledger/)
      end
    end

    it "stops on a case key it does not understand" do
      Dir.mktmpdir do |dir|
        digest = build_testsuite(dir, [cases.first.merge("configuration" => { "locale" => "fr" })])
        _entry, gen, payloads = described_class.verify(dir, "latex", 1, digest)
        expect { described_class.cases(gen, payloads) }
          .to raise_error(LatexmathStageCases::Error, /unsupported case keys configuration/)
      end
    end
  end

  describe ".run" do
    before { native_or_skip }

    it "writes raw-tree payloads and the stage-gem producer from both engines" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        out = File.join(dir, "out")
        digest = build_testsuite(testsuite, cases)
        summary = described_class.run(testsuite: testsuite, language: "latex", generation: 1, digest: digest,
                                      output: out, report: File.join(dir, "report.json"), log: StringIO.new)
        expect(summary["engine_disagreements"]).to be_empty
        expect(summary["legacy_differences"]).to be_empty

        payload = YAML.safe_load_file(File.join(out, "payloads/raw-sample.yaml"))
        expect(payload.values_at("schema", "group", "boundary"))
          .to eq(["plurimath-stage/latex/cases/1", "raw-sample", "raw-tree"])
        frac, brace = payload["cases"]
        expect(frac["id"]).to eq("latex-frac-simple.raw")
        expect(frac["input"]).to eq("str" => "\\frac{1}{2}")
        expect(frac["options"]).to eq("decimal" => ".")
        expect(frac.dig("expected", "preprocessed")).to eq("str" => "\\frac{1}{2}")
        expect(frac.dig("expected", "tree", "hash", 0, 0)).to eq("sym" => "binary")
        expect(brace).to eq("id" => "latex-stray-close-brace.raw", "input" => { "str" => "x}" }, "options" => { "decimal" => "." },
                            "expected" => { "refusal" => { "category" => "parse_error", "byte_offset" => 1 } })

        fragment = YAML.safe_load_file(File.join(out, "provenance-fragment.yaml"))
        producer = fragment.dig("producers", "latexmath-raw")
        expect(producer.values_at("kind", "semantic_boundary")).to eq(%w[stage-gem raw-tree])
        expect(producer.dig("generator", "path")).to eq("scripts/stage_cases.rb")
        generator = File.expand_path("../../scripts/stage_cases.rb", __dir__)
        expect(producer.dig("generator", "sha256")).to eq(Digest::SHA256.file(generator).hexdigest)
        expect(producer["inputs"].map { |i| i["path"] }).to eq(["stages/latex/generations/000001/payloads/sample.yaml"])
        expect(producer.dig("environment", "lml")).to be_nil
        expect(producer.dig("environment", "compiler", "version")).to eq(Parsanol::VERSION)
        expect(producer.dig("environment", "binding", "artifacts").map { |a| a["target"] }).to eq(%w[ruby rs ts python])
        expect(producer.dig("configuration", "engines")).to eq(%w[ruby native])
        entry = fragment["payloads"].first
        expect(entry.slice("path", "producer", "rows")).to eq(
          "path" => "payloads/raw-sample.yaml", "producer" => "latexmath-raw",
          "rows" => %w[latex-frac-simple.raw latex-stray-close-brace.raw],
        )
        expect(entry["sha256"]).to eq(Digest::SHA256.file(File.join(out, "payloads/raw-sample.yaml")).hexdigest)
      end
    end

    it "fails and writes nothing when the engines disagree" do
      allow(LatexmathStageCases::Parse).to receive(:outcome).and_call_original
      allow(LatexmathStageCases::Parse).to receive(:outcome).with("x}", :ruby)
                                                            .and_return([{ "refusal" => { "category" => "parse_error",
                                                                                          "byte_offset" => 0 } }, nil])
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        out = File.join(dir, "out")
        digest = build_testsuite(testsuite, cases)
        expect do
          described_class.run(testsuite: testsuite, language: "latex", generation: 1, digest: digest, output: out,
                              log: StringIO.new)
        end.to raise_error(LatexmathStageCases::EngineDisagreement, /latex-stray-close-brace/)
        expect(File.exist?(out)).to be(false)
      end
    end
  end
end
