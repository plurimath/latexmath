# frozen_string_literal: true

require "fileutils"
require "stringio"
require "tmpdir"
require "yaml"
require_relative "../parser/parser_helper"
require_relative "../../scripts/replay_corpus"

RSpec.describe LatexmathReplayCorpus do
  PIN_FILE = File.expand_path("../fixtures/testsuite-pin.yml", __dir__)

  # The expected value of latex-power-square.raw in latex generation 2.
  let(:square) do
    {
      "preprocessed" => { "str" => "x^2" },
      "tree" => { "hash" => [[{ "sym" => "power" }, { "hash" => [
        [{ "sym" => "symbols" }, { "slice" => "x", "byte_offset" => 0, "char_offset" => 0 }],
        [{ "sym" => "supscript" }, { "hash" => [
          [{ "sym" => "number" }, { "slice" => "2", "byte_offset" => 2, "char_offset" => 2 }],
        ] }],
      ] }]] },
    }
  end

  let(:refusal) { { "refusal" => { "category" => "parse_error", "byte_offset" => 0 } } }

  let(:raw_rows) do
    [
      { "id" => "square.raw", "input" => { "str" => "x^2" }, "options" => { "decimal" => "." },
        "expected" => square },
      { "id" => "refused.raw", "input" => { "str" => "}" }, "options" => { "decimal" => "." },
        "expected" => refusal },
    ]
  end

  # A testsuite checkout with one latex generation: a legacy payload, which
  # the replay skips, and a raw-tree payload of +rows+. Returns
  # [commit, snapshot digest].
  def build_testsuite(dir, rows)
    gen = File.join(dir, "stages/latex/generations/000001")
    FileUtils.mkdir_p(File.join(gen, "payloads"))
    legacy = { "schema" => "plurimath-corpus/latex/1", "group" => "sample",
               "cases" => [{ "id" => "square", "input" => "x^2" }] }
    raw = { "schema" => "plurimath-stage/latex/cases/1", "group" => "raw-sample", "boundary" => "raw-tree",
            "cases" => rows }
    File.binwrite(File.join(gen, "payloads/sample.yaml"), YAML.dump(legacy))
    File.binwrite(File.join(gen, "payloads/raw-sample.yaml"), YAML.dump(raw))
    provenance = { "schema" => "plurimath-stage/provenance/1", "language" => "latex", "generation" => 1,
                   "payloads" => [{ "path" => "payloads/raw-sample.yaml" }, { "path" => "payloads/sample.yaml" }] }
    File.binwrite(File.join(gen, "provenance.yaml"), YAML.dump(provenance))
    digest = LatexmathStageCases::Source.snapshot_digest(gen)
    FileUtils.mkdir_p(File.join(dir, "generations"))
    ledger = { "schema" => "plurimath-stage/ledger/1", "language" => "latex", "layout" => 1,
               "entries" => [{ "generation" => 1, "path" => "stages/latex/generations/000001",
                               "snapshot_digest" => digest }] }
    File.binwrite(File.join(dir, "generations/latex.yaml"), YAML.dump(ledger))
    git = ["git", "-C", dir, "-c", "user.name=t", "-c", "user.email=t@example.com"]
    system("git", "init", "-q", dir, exception: true)
    system(*git, "add", ".", exception: true)
    system(*git, "commit", "-qm", "t", exception: true)
    [LatexmathStageCases::Identity.git(dir, "rev-parse", "HEAD"), digest]
  end

  def write_pin(path, **fields)
    pin = { "schema" => "plurimath-stage/pin/1", "repository" => "https://github.com/plurimath/plurimath-testsuite",
            "commit" => nil, "language" => "latex", "generation" => 1, "snapshot_digest" => nil }
    File.binwrite(path, YAML.dump(pin.merge(fields.transform_keys(&:to_s)).compact))
    path
  end

  def run_replay(testsuite, pin, **options)
    described_class.run(testsuite: testsuite, pin: pin, log: StringIO.new, **options)
  end

  describe "the committed pin" do
    it "names latex generation 2 at an exact testsuite commit" do
      pin = described_class.load_pin(PIN_FILE)
      expect(pin.language).to eq("latex")
      expect(pin.generation).to eq(2)
      expect(pin.commit).to match(/\A\h{40}\z/)
      expect(pin.digest).to match(/\Asha256:\h{64}\z/)
    end
  end

  describe ".load_pin" do
    it "refuses a pin with a missing, unknown or malformed field" do
      Dir.mktmpdir do |dir|
        good = { commit: "a" * 40, snapshot_digest: "sha256:#{'0' * 64}" }
        expect(described_class.load_pin(write_pin(File.join(dir, "ok.yml"), **good)).generation).to eq(1)
        {
          "schema" => { schema: "plurimath-stage/pin/2" },
          "repository" => { repository: "https://github.com/plurimath/plurimath" },
          "commit" => { commit: "fac6950" },
          "language" => { language: "pma" },
          "generation" => { generation: 0 },
          "snapshot_digest" => { snapshot_digest: "bad80c8a" },
          "missing" => { snapshot_digest: nil },
        }.each do |name, change|
          path = write_pin(File.join(dir, "#{name}.yml"), **good, **change)
          expect { described_class.load_pin(path) }.to raise_error(described_class::Error), name
        end
        File.binwrite(File.join(dir, "extra.yml"), YAML.dump(YAML.load_file(File.join(dir, "ok.yml")).merge("x" => 1)))
        expect { described_class.load_pin(File.join(dir, "extra.yml")) }
          .to raise_error(described_class::Error, /unknown keys x/)
      end
    end
  end

  describe ".run" do
    before { native_or_skip }

    it "replays every raw-tree row on both engines when the pin matches" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        commit, digest = build_testsuite(testsuite, raw_rows)
        pin = write_pin(File.join(dir, "pin.yml"), commit: commit, snapshot_digest: digest)
        summary = run_replay(testsuite, pin, language: "latex", generation: 1)
        expect(summary.values_at("raw_tree_payloads", "raw_tree_rows", "mismatched_rows")).to eq([1, 2, 0])
        expect(summary["engines"]).to eq(%w[ruby native])
      end
    end

    it "fails when the pinned commit is not the checkout's HEAD" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        _commit, digest = build_testsuite(testsuite, raw_rows)
        pin = write_pin(File.join(dir, "pin.yml"), commit: "0" * 40, snapshot_digest: digest)
        expect { run_replay(testsuite, pin) }.to raise_error(described_class::Error, /is not the checkout's HEAD/)
      end
    end

    it "fails when the pinned digest is not the generation's" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        commit, = build_testsuite(testsuite, raw_rows)
        pin = write_pin(File.join(dir, "pin.yml"), commit: commit, snapshot_digest: "sha256:#{'0' * 64}")
        expect { run_replay(testsuite, pin) }.to raise_error(described_class::Error, /is not the expected sha256:0{64}/)
      end
    end

    it "fails when a generation file no longer matches the ledger digest" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        commit, digest = build_testsuite(testsuite, raw_rows)
        pin = write_pin(File.join(dir, "pin.yml"), commit: commit, snapshot_digest: digest)
        File.open(File.join(testsuite, "stages/latex/generations/000001/payloads/sample.yaml"), "ab") { |io| io.write("tampered\n") }
        expect { run_replay(testsuite, pin) }.to raise_error(described_class::Error, /does not match the ledger's/)
      end
    end

    it "fails when the pinned generation is not in the ledger" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        commit, digest = build_testsuite(testsuite, raw_rows)
        pin = write_pin(File.join(dir, "pin.yml"), commit: commit, generation: 2, snapshot_digest: digest)
        expect { run_replay(testsuite, pin) }.to raise_error(described_class::Error, /has no generation 2/)
      end
    end

    it "fails when the caller expects another generation or language than the pin's" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        commit, digest = build_testsuite(testsuite, raw_rows)
        pin = write_pin(File.join(dir, "pin.yml"), commit: commit, snapshot_digest: digest)
        expect { run_replay(testsuite, pin, generation: 2) }
          .to raise_error(described_class::Error, /--generation 2 is not the pinned 1/)
        expect { run_replay(testsuite, pin, language: "unicode") }
          .to raise_error(described_class::Error, /--language unicode is not the pinned latex/)
      end
    end

    it "fails and reports the row when a parse differs from the expected value" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        rows = raw_rows.dup
        rows[1] = rows[1].merge("expected" => { "refusal" => { "category" => "parse_error", "byte_offset" => 1 } })
        commit, digest = build_testsuite(testsuite, rows)
        pin = write_pin(File.join(dir, "pin.yml"), commit: commit, snapshot_digest: digest)
        report = File.join(dir, "report.json")
        expect { run_replay(testsuite, pin, report: report) }
          .to raise_error(described_class::Error, /1 rows differ: refused\.raw/)
        failures = JSON.parse(File.read(report)).fetch("failures")
        expect(failures.map { |f| [f["id"], f["mismatches"].map { |m| m["engine"] }] })
          .to eq([["refused.raw", %w[ruby native]]])
      end
    end

    it "fails when the generation has no raw-tree rows" do
      Dir.mktmpdir do |dir|
        testsuite = File.join(dir, "testsuite")
        commit, digest = build_testsuite(testsuite, [])
        pin = write_pin(File.join(dir, "pin.yml"), commit: commit, snapshot_digest: digest)
        expect { run_replay(testsuite, pin) }.to raise_error(described_class::Error, /has no raw-tree rows/)
      end
    end
  end
end
