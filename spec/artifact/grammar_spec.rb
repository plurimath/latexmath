# frozen_string_literal: true

require_relative "artifact_helper"

RSpec.describe "the grammar build inputs" do
  let(:data) { JSON.parse(File.binread(ArtifactSpecHelpers::DATA)) }
  let(:pins) { YAML.safe_load_file(File.join(ArtifactSpecHelpers::ROOT, "scripts", "oracle", "pins.yml")) }

  it "is generated from the committed export (generate_grammar.rb --check)" do
    out, status = Open3.capture2e(RbConfig.ruby, File.join(ArtifactSpecHelpers::ROOT, "scripts", "generate_grammar.rb"),
                                  "--check")
    expect(status).to be_success, out
  end

  it "records the pinned oracle commit and the legacy LaTeX sources" do
    expect(data["format"]).to eq("latexmath-atoms/v1")
    expect(data["oracle"]).to include("repository" => pins.dig("plurimath", "repository"),
                                      "commit" => pins.dig("plurimath", "commit"))
    expect(data.dig("oracle", "lib_tree")).to match(/\A\h{40}\z/)
    expected = pins.dig("plurimath", "latex_sources").transform_values { |sum| "sha256:#{sum}" }
    expect(data.dig("oracle", "latex_sources")).to eq(expected)
  end

  it "has one entry per decimal marker, in the legacy encoded form" do
    markers = data["markers"].to_h { |m| [m["decimal"], [m["name"], m["encoded"]]] }
    expect(markers).to eq("." => %w[dot .], "," => %w[comma ,], "٫" => ["arabic", "&#x66b;"])
  end

  it "names the export checksum in the generated grammar's header" do
    header = File.foreach(ArtifactSpecHelpers::GRAMMAR).first(8).join
    expect(header).to include("data/latex-atoms.json sha256:#{Digest::SHA256.file(ArtifactSpecHelpers::DATA).hexdigest}")
  end

  it "is pure ASCII" do
    expect(File.binread(ArtifactSpecHelpers::GRAMMAR)).to be_ascii_only
  end
end
