# frozen_string_literal: true

require "open3"
require "tmpdir"
require_relative "../../scripts/oracle/lib/latexmath_oracle/oracle_env"

RSpec.describe LatexmathOracle::OracleEnv do
  let(:tmp) { Dir.mktmpdir("latexmath-oracle-env") }
  let(:checkout) { File.join(tmp, "plurimath") }
  let(:lock) { File.join(tmp, "oracle.gemfile.lock") }

  after { FileUtils.remove_entry(tmp) }

  def git(*args)
    out, status = Open3.capture2e("git", "-C", checkout, *args)
    raise out unless status.success?

    out.strip
  end

  def sha256(text)
    Digest::SHA256.hexdigest(text)
  end

  before do
    FileUtils.mkdir_p(File.join(checkout, "lib"))
    File.write(File.join(checkout, "lib/parse.rb"), "grammar\n")
    git("init", "-q")
    git("add", "lib/parse.rb")
    git("-c", "user.name=spec", "-c", "user.email=spec@example.com", "commit", "-q", "-m", "pin")
    File.write(File.join(checkout, ".git/info/exclude"), "/.latexmath-oracle/\n")
    File.write(lock, "LOCK\n")
  end

  def env(commit: git("rev-parse", "HEAD"), source: sha256("grammar\n"))
    pins = { "plurimath" => { "repository" => "https://example.com/plurimath", "commit" => commit,
                              "latex_sources" => { "lib/parse.rb" => source } } }
    described_class.new(checkout, pins: pins, lock: lock)
  end

  def install_lock(text = "LOCK\n")
    FileUtils.mkdir_p(File.join(checkout, ".latexmath-oracle"))
    File.write(File.join(checkout, ".latexmath-oracle/Gemfile.lock"), text)
  end

  it "accepts a clean checkout at the pinned commit with the committed lock" do
    install_lock
    expect { env.verify! }.not_to raise_error
    expect(env.identity).to include("plurimath_commit" => git("rev-parse", "HEAD"),
                                    "lock_sha256" => sha256("LOCK\n"))
  end

  it "rejects a checkout at another commit" do
    expect { env(commit: "0" * 40).verify_checkout! }
      .to raise_error(LatexmathOracle::Error, /pins.yml requires 0{40}/)
  end

  it "rejects a checkout with local changes" do
    File.write(File.join(checkout, "lib/parse.rb"), "edited\n")
    expect { env.verify_checkout! }.to raise_error(LatexmathOracle::Error, /local changes/)
  end

  it "rejects a pinned source whose checksum differs" do
    expect { env(source: "f" * 64).verify_checkout! }
      .to raise_error(LatexmathOracle::Error, %r{lib/parse.rb is})
  end

  it "rejects a missing or different installed lock" do
    expect { env.verify_lock! }.to raise_error(LatexmathOracle::Error, /setup.rb/)
    install_lock("OTHER\n")
    expect { env.verify_lock! }.to raise_error(LatexmathOracle::Error, /differs/)
  end

  it "points the child at the oracle bundle only" do
    child = env.child_env
    expect(child["BUNDLE_GEMFILE"]).to eq(File.join(checkout, ".latexmath-oracle/Gemfile"))
    expect(env.command.last).to end_with("scripts/oracle/latex_worker.rb")
  end
end

RSpec.describe "committed oracle inputs" do
  root = File.expand_path("../..", __dir__)

  it "has a smoke inventory with the rows the smoke capture selects" do
    inventory = LatexmathOracle::Inventory.load(File.join(root, "corpora/oracle/smoke.yaml"))
    expect(inventory.select(%w[smoke-success smoke-refusal]).size).to eq(2)
  end

  it "pins every legacy LaTeX source by checksum" do
    pins = YAML.safe_load(File.read(File.join(root, "scripts/oracle/pins.yml")))
    expect(pins.dig("plurimath", "commit")).to match(/\A\h{40}\z/)
    expect(pins.dig("plurimath", "latex_sources").values).to all(match(/\A\h{64}\z/))
  end
end
