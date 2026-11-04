# frozen_string_literal: true

# Replays the plurimath-testsuite stage generation pinned in
# spec/fixtures/testsuite-pin.yml through this gem.
#
#   bundle exec ruby scripts/replay_corpus.rb --testsuite PATH \
#     [--pin FILE] [--language latex] [--generation N] [--report FILE]
#
# Before any row runs it checks the pin: its schema and fields, that the
# testsuite checkout is at the pinned commit, that the ledger has the pinned
# generation with the pinned snapshot digest, and that the digest recomputed
# from the generation's files is the same. --language and --generation, when
# given, must equal the pin's; they guard a caller that expects a particular
# generation.
#
# Then every row of every raw-tree payload of that generation is parsed with
# Latexmath::RawParser.parse on the Ruby and the native engine, with the row's
# options, and each engine's outcome (preprocessed text and tree, or refusal
# and its byte offset) must equal the row's expected value, in the canonical
# tagged form of the testsuite's docs/tree-parity-contract.adoc. Any pin
# failure, any difference or a generation with no raw-tree rows exits 1.

require "json"
require "optparse"
require "yaml"
require_relative "stage_cases"

module LatexmathReplayCorpus
  class Error < StandardError; end

  ROOT = File.expand_path("..", __dir__)
  DEFAULT_PIN = File.join(ROOT, "spec", "fixtures", "testsuite-pin.yml")
  PIN_SCHEMA = "plurimath-stage/pin/1"
  PIN_KEYS = %w[schema repository commit language generation snapshot_digest].freeze
  REPOSITORY = LatexmathStageCases::TESTSUITE_REPOSITORY
  LANGUAGES = LatexmathStageCases::LANGUAGES
  ENGINES = LatexmathStageCases::ENGINES
  OPTION_KEYS = %w[decimal].freeze

  Pin = Struct.new(:commit, :language, :generation, :digest, keyword_init: true)

  module_function

  # The pin at +path+, its fields checked against plurimath-stage/pin/1.
  def load_pin(path)
    doc = YAML.safe_load_file(path, aliases: false)
    raise Error, "#{path}: not a mapping" unless doc.is_a?(Hash)

    missing = PIN_KEYS - doc.keys
    extra = doc.keys - PIN_KEYS
    raise Error, "#{path}: missing #{missing.join(', ')}" unless missing.empty?
    raise Error, "#{path}: unknown keys #{extra.join(', ')}" unless extra.empty?
    raise Error, "#{path}: schema is not #{PIN_SCHEMA}" unless doc["schema"] == PIN_SCHEMA
    raise Error, "#{path}: repository is not #{REPOSITORY}" unless doc["repository"] == REPOSITORY
    raise Error, "#{path}: commit is not a 40-hex commit" unless doc["commit"].is_a?(String) && doc["commit"].match?(/\A\h{40}\z/)
    raise Error, "#{path}: language #{doc['language'].inspect} is not one of #{LANGUAGES.join(', ')}" unless LANGUAGES.include?(doc["language"])
    raise Error, "#{path}: generation is not a positive integer" unless doc["generation"].is_a?(Integer) && doc["generation"] >= 1
    unless doc["snapshot_digest"].is_a?(String) && doc["snapshot_digest"].match?(/\Asha256:\h{64}\z/)
      raise Error, "#{path}: snapshot_digest is not sha256:<64 hex>"
    end

    Pin.new(commit: doc["commit"], language: doc["language"], generation: doc["generation"],
            digest: doc["snapshot_digest"])
  rescue Psych::Exception, Errno::ENOENT => e
    raise Error, "#{path}: #{e.message}"
  end

  # [generation dir, payload paths] once the checkout matches +pin+.
  def verify(testsuite, pin)
    head = LatexmathStageCases::Identity.git(testsuite, "rev-parse", "HEAD")
    raise Error, "pin commit #{pin.commit} is not the checkout's HEAD #{head}" unless head == pin.commit

    _entry, dir, payloads = LatexmathStageCases::Source.verify(testsuite, pin.language, pin.generation, pin.digest)
    [dir, payloads]
  rescue LatexmathStageCases::Error => e
    raise Error, e.message
  end

  # A canonical {str:} or {bytes:, encoding:} value as a Ruby string.
  def decode(value, where)
    if value.is_a?(Hash) && value.keys == ["str"] && value["str"].is_a?(String)
      value["str"]
    elsif value.is_a?(Hash) && value.keys.sort == %w[bytes encoding] && value["bytes"].is_a?(String)
      [value["bytes"]].pack("H*").force_encoding(Encoding.find(value["encoding"]))
    else
      raise Error, "#{where}: input is not a canonical string"
    end
  end

  def options(row, where)
    opts = row.fetch("options", {})
    unknown = opts.keys - OPTION_KEYS
    raise Error, "#{where}: unsupported options #{unknown.join(', ')}" unless unknown.empty?

    opts.transform_keys(&:to_sym)
  end

  # Every raw-tree row of the generation, with its payload path.
  def raw_rows(dir, payload_paths)
    payload_paths.flat_map do |rel|
      doc = YAML.safe_load_file(File.join(dir, rel), aliases: false)
      next [] unless doc["boundary"] == "raw-tree"

      doc.fetch("cases").map { |row| [rel, row] }
    end
  end

  def outcome(input, opts, engine)
    if opts.fetch(:decimal, LatexmathStageCases::DECIMAL) != LatexmathStageCases::DECIMAL
      raise Error, "decimal #{opts[:decimal].inspect} is not supported by the replay"
    end

    LatexmathStageCases::Parse.outcome(input, engine).first
  rescue LatexmathStageCases::Error => e
    raise Error, e.message
  end

  def replay(rows)
    rows.filter_map do |rel, row|
      where = "#{rel} #{row['id']}"
      input = decode(row.fetch("input"), where)
      opts = options(row, where)
      expected = row.fetch("expected")
      wrong = ENGINES.filter_map do |engine|
        actual = outcome(input, opts, engine)
        { "engine" => engine.to_s, "actual" => actual } unless actual == expected
      end
      { "id" => row["id"], "payload" => rel, "expected" => expected, "mismatches" => wrong } unless wrong.empty?
    end
  end

  def run(testsuite:, pin: DEFAULT_PIN, language: nil, generation: nil, report: nil, log: $stderr)
    pinned = load_pin(pin)
    raise Error, "--language #{language} is not the pinned #{pinned.language}" if language && language != pinned.language
    if generation && generation != pinned.generation
      raise Error, "--generation #{generation} is not the pinned #{pinned.generation}"
    end
    raise Error, "the native engine is not available" unless Latexmath::Engine.native_available?

    dir, payloads = verify(File.expand_path(testsuite), pinned)
    rows = raw_rows(dir, payloads)
    raise Error, "#{pinned.language} generation #{pinned.generation} has no raw-tree rows" if rows.empty?

    log.puts "pin ok: #{pinned.language} generation #{pinned.generation} at #{pinned.commit}, #{pinned.digest}"
    failures = replay(rows)
    summary = { "commit" => pinned.commit, "language" => pinned.language, "generation" => pinned.generation,
                "snapshot_digest" => pinned.digest, "engines" => ENGINES.map(&:to_s),
                "raw_tree_payloads" => rows.map(&:first).uniq.size, "raw_tree_rows" => rows.size,
                "mismatched_rows" => failures.size, "failures" => failures }
    if report
      FileUtils.mkdir_p(File.dirname(report))
      File.write(report, "#{JSON.pretty_generate(summary, max_nesting: false)}\n")
    end
    log.puts "#{rows.size} raw-tree rows from #{summary['raw_tree_payloads']} payloads on " \
             "#{ENGINES.join(' and ')}: #{failures.size} differ"
    raise Error, "#{failures.size} rows differ: #{failures.map { |f| f['id'] }.join(', ')}" unless failures.empty?

    summary
  end

  def main(argv)
    options = {}
    OptionParser.new do |o|
      o.banner = "usage: scripts/replay_corpus.rb --testsuite PATH [--pin FILE] [--report FILE]"
      o.on("--testsuite PATH") { |v| options[:testsuite] = v }
      o.on("--pin FILE") { |v| options[:pin] = v }
      o.on("--language NAME") { |v| options[:language] = v }
      o.on("--generation N", Integer) { |v| options[:generation] = v }
      o.on("--report FILE") { |v| options[:report] = v }
    end.parse!(argv)
    raise OptionParser::MissingArgument, "--testsuite" unless options[:testsuite]

    run(**options)
    0
  rescue OptionParser::ParseError => e
    warn e.message
    2
  rescue Error => e
    warn "replay_corpus: #{e.message}"
    1
  end
end

if $PROGRAM_NAME == __FILE__
  $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
  require "latexmath/parser"
  exit LatexmathReplayCorpus.main(ARGV)
end
