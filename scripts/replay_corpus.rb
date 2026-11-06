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
# tagged form of the testsuite's docs/tree-parity-contract.adoc.
#
# Every row of every typed-model payload is parsed with Latexmath.parse on
# both engines the same way and compared in the form scripts/stage_cases.rb
# writes (each model object with its set fields in declaration order). A
# derived attribute (one computed from the bound data, such as
# MathSymbol#value and #kind) that a row's object does not record is left out
# of the comparison and reported, because the row was written before the
# model declared it; a derived attribute the row does record must match.
# Everything else must be equal.
#
# Any pin failure, any difference or a generation with no raw-tree rows
# exits 1. A generation with no typed-model rows replays its raw-tree rows
# only.

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

  # Every row of the generation's +boundary+ payloads, with its payload path.
  def rows(dir, payload_paths, boundary)
    payload_paths.flat_map do |rel|
      doc = YAML.safe_load_file(File.join(dir, rel), aliases: false)
      next [] unless doc["boundary"] == boundary

      doc.fetch("cases").map { |row| [rel, row] }
    end
  end

  def raw_rows(dir, payload_paths)
    rows(dir, payload_paths, "raw-tree")
  end

  def model_rows(dir, payload_paths)
    rows(dir, payload_paths, "typed-model")
  end

  def outcome(input, opts, engine, boundary = "raw-tree")
    if opts.fetch(:decimal, LatexmathStageCases::DECIMAL) != LatexmathStageCases::DECIMAL
      raise Error, "decimal #{opts[:decimal].inspect} is not supported by the replay"
    end

    if boundary == "typed-model"
      LatexmathStageCases::Parse.model_outcome(input, engine).first
    else
      LatexmathStageCases::Parse.outcome(input, engine).first
    end
  rescue LatexmathStageCases::Error => e
    raise Error, e.message
  end

  # The typed-model comparison: +actual+ without the derived attributes
  # that the matching object of +expected+ does not record. The names of
  # the attributes left out ("<model class>#<attribute>") are added to
  # +omitted+.
  module ModelCompare
    module_function

    def project(actual, expected, omitted)
      return node(actual, expected, omitted) if node?(actual)
      return actual unless actual.is_a?(Hash)

      expected = {} unless expected.is_a?(Hash)
      if actual.keys == ["array"]
        items = Array(expected["array"])
        return { "array" => actual["array"].each_with_index.map { |item, i| project(item, items[i], omitted) } }
      end
      actual.to_h { |key, value| [key, project(value, expected[key], omitted)] }
    end

    def node?(value)
      value.is_a?(Hash) && value.keys == %w[node fields]
    end

    def node(actual, expected, omitted)
      return actual unless node?(expected) && expected["node"] == actual["node"]

      { "node" => actual["node"], "fields" => fields(actual, expected["fields"].to_h, omitted) }
    end

    # The fields of +actual+ without the derived attributes +recorded+ has
    # no entry for.
    def fields(actual, recorded, omitted)
      klass = model_class(actual["node"])
      actual["fields"].filter_map do |name, value|
        if !recorded.key?(name) && derived?(klass, name)
          omitted << "#{actual['node']}##{name}"
          next
        end
        [name, project(value, recorded[name], omitted)]
      end
    end

    def model_class(name)
      return nil unless name.is_a?(String) && name.start_with?("Latexmath::Model::")

      Object.const_get(name)
    rescue NameError
      nil
    end

    def derived?(klass, name)
      return false unless klass.respond_to?(:attributes)

      attribute = klass.attributes[name.to_sym] || klass.attributes[name]
      attribute.respond_to?(:derived?) && attribute.derived?
    end
  end

  # [mismatched rows, rows equal only once unrecorded derived attributes
  # are left out] of +rows+ at +boundary+.
  def replay(rows, boundary = "raw-tree")
    omitted_rows = []
    failures = rows.filter_map do |rel, row|
      where = "#{rel} #{row['id']}"
      input = decode(row.fetch("input"), where)
      opts = options(row, where)
      expected = row.fetch("expected")
      omitted = []
      wrong = ENGINES.filter_map do |engine|
        actual = outcome(input, opts, engine, boundary)
        actual = ModelCompare.project(actual, expected, omitted) if boundary == "typed-model"
        { "engine" => engine.to_s, "actual" => actual } unless actual == expected
      end
      if wrong.empty? && !omitted.empty?
        omitted_rows << { "id" => row["id"], "payload" => rel, "omitted" => omitted.uniq.sort }
      end
      next if wrong.empty?

      { "id" => row["id"], "payload" => rel, "boundary" => boundary, "expected" => expected, "mismatches" => wrong }
    end
    [failures, omitted_rows]
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

    models = model_rows(dir, payloads)
    log.puts "pin ok: #{pinned.language} generation #{pinned.generation} at #{pinned.commit}, #{pinned.digest}"
    raw_failures, = replay(rows)
    log.puts "#{rows.size} raw-tree rows from #{rows.map(&:first).uniq.size} payloads on " \
             "#{ENGINES.join(' and ')}: #{raw_failures.size} differ"
    model_failures, omitted = replay(models, "typed-model")
    log_models(log, models, model_failures, omitted)

    failures = raw_failures + model_failures
    summary = { "commit" => pinned.commit, "language" => pinned.language, "generation" => pinned.generation,
                "snapshot_digest" => pinned.digest, "engines" => ENGINES.map(&:to_s),
                "raw_tree_payloads" => rows.map(&:first).uniq.size, "raw_tree_rows" => rows.size,
                "typed_model_payloads" => models.map(&:first).uniq.size, "typed_model_rows" => models.size,
                "mismatched_rows" => failures.size,
                "unrecorded_derived_attributes" => omitted.flat_map { |r| r["omitted"] }.uniq.sort,
                "unrecorded_derived_rows" => omitted, "failures" => failures }
    if report
      FileUtils.mkdir_p(File.dirname(report))
      File.binwrite(report, "#{JSON.pretty_generate(summary, max_nesting: false)}\n")
    end
    raise Error, "#{failures.size} rows differ: #{failures.map { |f| f['id'] }.join(', ')}" unless failures.empty?

    summary
  end

  def log_models(log, models, failures, omitted)
    return log.puts("no typed-model rows") if models.empty?

    log.puts "#{models.size} typed-model rows from #{models.map(&:first).uniq.size} payloads on " \
             "#{ENGINES.join(' and ')}: #{failures.size} differ"
    return if omitted.empty?

    names = omitted.flat_map { |r| r["omitted"] }.uniq.sort
    log.puts "#{omitted.size} typed-model rows do not record the derived attributes #{names.join(', ')}; " \
             "they were compared without them"
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
