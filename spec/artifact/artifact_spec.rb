# frozen_string_literal: true

require_relative "artifact_helper"

RSpec.describe "the compiled artifacts" do
  def manifest_value(key)
    line = manifest.find { |l| l.start_with?("#{key} ") }
    line&.split(" ", 2)&.last
  end

  it "match the checksum manifest" do
    files = manifest.filter_map { |l| l.match(%r{\A(\S+/\S+) sha256:(\h{64})\z}) }
    expect(files.map { |m| m[1] }).to include("artifacts/latex.json", "grammars/latex.parg",
                                              "data/latex-atoms.json",
                                              *ArtifactSpecHelpers::TARGETS.map { |t| "artifacts/latex.bindings.#{t}.json" })
    files.each do |m|
      expect(Digest::SHA256.file(File.join(ArtifactSpecHelpers::ROOT, m[1])).hexdigest).to eq(m[2]), m[1]
    end
  end

  it "records the envelope checksum, compiler, source hash, entries and order warnings" do
    expect(manifest_value("artifact_checksum")).to eq(envelope["checksum"])
    expect(manifest_value("compiler_version")).to eq(envelope["compiler_version"])
    expect(manifest_value("source_hash")).to eq("sha256:#{Digest::SHA256.file(ArtifactSpecHelpers::GRAMMAR).hexdigest}")
    expect(envelope["source_hash"]).to eq(Digest::SHA256.file(ArtifactSpecHelpers::GRAMMAR).hexdigest)
    expect(manifest_value("entries").split).to eq(ArtifactSpecHelpers::ENTRIES)
    expect(manifest_value("order_warnings")).to eq(envelope.dig("lint", "order_warnings").size.to_s)
  end

  it "is fresh against the grammar source" do
    parse = Latexmath::Artifact.load_parse(ArtifactSpecHelpers::ARTIFACT)
    expect(parse.fresh_against?(File.read(ArtifactSpecHelpers::GRAMMAR, encoding: "UTF-8"))).to be(true)
  end

  it "declares the tree capture as a raw and a model binding for every entry" do
    expect(envelope["entries"].keys).to eq(ArtifactSpecHelpers::ENTRIES)
    envelope["entries"].each_value do |entry|
      expect(entry["bindings"]).to eq([{ "capture" => "latex_tree", "path" => "latex_tree",
                                         "type" => "raw", "card" => nil, "preprocess" => nil },
                                       { "capture" => "latex_tree", "path" => "model",
                                         "type" => "any", "card" => nil, "preprocess" => nil }])
    end
  end

  ArtifactSpecHelpers::TARGETS.each do |target|
    it "ships a verified #{target} bindings artifact that pairs with the parse artifact" do
      parse = Latexmath::Artifact.load_parse(ArtifactSpecHelpers::ARTIFACT)
      bindings = Parsanol::PARG::Bindings::Artifact.from_json(File.read(bindings_path(target)), target: target)
      expect(bindings.payload["artifact_kind"]).to eq("parg-bindings")
      expect(bindings.binding_version).to eq(1)
      expect(bindings.grammar_source_hash).to eq(envelope["source_hash"])
      expect(manifest).to include("bindings #{target} checksum #{bindings.payload['checksum']}")
      expect { bindings.pair_with!(parse) }.not_to raise_error
      expect(bindings.entry_names).to eq(ArtifactSpecHelpers::ENTRIES)
    end
  end
end

RSpec.describe Latexmath::Artifact do
  let(:parse) { described_class.load_parse(ArtifactSpecHelpers::ARTIFACT) }

  def write(dir, name, text)
    File.join(dir, name).tap { |path| File.write(path, text) }
  end

  it "loads and pairs the bundled artifacts" do
    bindings = described_class.load_bindings(bindings_path("ruby"), parse)
    expect(bindings.target).to eq("ruby")
  end

  it "refuses a missing parse artifact" do
    expect { described_class.load_parse("/nonexistent/latex.json") }
      .to raise_error(Latexmath::ArtifactError, /not found/)
  end

  it "refuses a parse artifact that is not JSON" do
    Dir.mktmpdir do |dir|
      expect { described_class.load_parse(write(dir, "a.json", "{")) }
        .to raise_error(Latexmath::ArtifactError, /not valid JSON/)
    end
  end

  it "refuses a tampered parse artifact" do
    Dir.mktmpdir do |dir|
      text = File.read(ArtifactSpecHelpers::ARTIFACT).sub('"version":"0.1.0"', '"version":"0.1.1"')
      expect(text).not_to eq(File.read(ArtifactSpecHelpers::ARTIFACT))
      expect { described_class.load_parse(write(dir, "a.json", text)) }
        .to raise_error(Latexmath::ArtifactError, /checksum/)
    end
  end

  it "refuses a parse artifact without a required entry" do
    Dir.mktmpdir do |dir|
      doc = JSON.parse(File.read(ArtifactSpecHelpers::ARTIFACT))
      doc["entries"].delete("arabic")
      # Without the byte checksum only the canonical checksum is verified.
      doc.delete("checksum")
      doc.delete("byte_checksum")
      doc["checksum"] = Parsanol::PARG::Compiler.checksum(doc)
      expect { described_class.load_parse(write(dir, "a.json", JSON.generate(doc))) }
        .to raise_error(Latexmath::ArtifactError, /lacks required entries: arabic/)
    end
  end

  it "refuses a missing bindings artifact" do
    expect { described_class.load_bindings("/nonexistent/b.json", parse) }
      .to raise_error(Latexmath::ArtifactError, /not found/)
  end

  it "refuses a tampered bindings artifact" do
    Dir.mktmpdir do |dir|
      text = altered_bindings("ruby", keep_checksum: true, grammar_version: "9.9.9")
      expect { described_class.load_bindings(write(dir, "b.json", text), parse) }
        .to raise_error(Latexmath::ArtifactError, /checksum mismatch/)
    end
  end

  it "refuses a bindings artifact for another target, kind or binding version" do
    Dir.mktmpdir do |dir|
      expect { described_class.load_bindings(bindings_path("ts"), parse) }
        .to raise_error(Latexmath::ArtifactError, /targets "ts", not "ruby"/)
      text = altered_bindings("ruby", artifact_kind: "parg-artifact")
      expect { described_class.load_bindings(write(dir, "b.json", text), parse) }
        .to raise_error(Latexmath::ArtifactError, /not a parg-bindings artifact/)
      text = altered_bindings("ruby", binding_version: 2)
      expect { described_class.load_bindings(write(dir, "c.json", text), parse) }
        .to raise_error(Latexmath::ArtifactError, /unsupported binding_version/)
    end
  end

  it "refuses bindings that do not pair with the parse artifact" do
    Dir.mktmpdir do |dir|
      text = altered_bindings("ruby", grammar_source_hash: "0" * 64)
      expect { described_class.load_bindings(write(dir, "b.json", text), parse) }
        .to raise_error(Latexmath::ArtifactError, /does not pair .*source_hash/)
      text = altered_bindings("ruby", grammar_version: "0.0.9")
      expect { described_class.load_bindings(write(dir, "c.json", text), parse) }
        .to raise_error(Latexmath::ArtifactError, /does not pair .*version/)
      text = altered_bindings("ruby", grammar: "Asciimath")
      expect { described_class.load_bindings(write(dir, "d.json", text), parse) }
        .to raise_error(Latexmath::ArtifactError, /does not pair .*grammar/)
    end
  end

  it "refuses bindings that do not carry the tree capture" do
    Dir.mktmpdir do |dir|
      entries = JSON.parse(File.read(bindings_path("ruby")))["entries"]
      entries["dot"] = { "bindings" => [] }
      text = altered_bindings("ruby", entries: entries)
      expect { described_class.load_bindings(write(dir, "b.json", text), parse) }
        .to raise_error(Latexmath::ArtifactError, /does not bind latex_tree for entry dot/)
    end
  end

  it "makes the parser refuse to run on an unpaired artifact set" do
    Dir.mktmpdir do |dir|
      bad = write(dir, "b.json", altered_bindings("ruby", grammar_source_hash: "0" * 64))
      with_artifacts(ArtifactSpecHelpers::ARTIFACT, bad) do
        expect { Latexmath::RawParser.parse("a", engine: :ruby) }
          .to raise_error(Latexmath::ArtifactError, /does not pair/)
      end
    end
  end
end
