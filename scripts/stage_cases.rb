# frozen_string_literal: true

# Writes plurimath-testsuite stage-case payloads (plurimath-stage/latex/cases/1,
# boundary raw-tree or typed-model) from one generation of the testsuite's
# LaTeX stage corpus.
#
#   bundle exec ruby scripts/stage_cases.rb \
#     --testsuite PATH --language latex --generation 1 \
#     --digest sha256:<64 hex> --output DIR [--report FILE] \
#     [--boundary raw-tree|typed-model]
#
# It verifies the generation's snapshot digest against both the ledger and
# --digest, reads every case's id and input (rejection rows included), and
# parses each input with Latexmath::RawParser.parse on the Ruby and the
# native engine. The two engines must give the same outcome; any difference
# fails the run and nothing is written.
#
# Into DIR it writes payloads/raw-<group>.yaml, one per source payload, with
# row ids "<id>.raw", and provenance-fragment.yaml: the stage-gem producer
# block and the payload entries for the generation's provenance.yaml. With
# --report it also writes a JSON comparison of each row with the source
# generation's legacy preprocessed text, parse_tree and refusal index; a
# difference there is reported, never corrected, and does not fail the run.
#
# With --boundary typed-model it parses each input with Latexmath.parse
# instead and writes payloads/model-<group>.yaml with row ids "<id>.model":
# the typed model (Latexmath::Model::Document), written from the bound data
# the model is built from (the model binding's `(any)` output) and typed by
# the declared model attributes. Each object is {node: <model class>,
# fields: [...]} with its set fields in declaration order; nil fields are
# left out. A walk of the built model through its declared attributes must
# give the same value, or the run stops. lutaml-model serialization is never
# used. The producer block names the committed LML export (model/latex.lml.json).
#
# Values are written in the canonical tagged form of the testsuite's
# docs/tree-parity-contract.adoc. Strings carry no Ruby encoding label: text
# whose bytes are valid UTF-8 is {str: ...} whatever its label.

require "digest"
require "fileutils"
require "json"
require "open3"
require "optparse"
require "yaml"

module LatexmathStageCases
  class Error < StandardError; end

  # The engines disagreed on at least one row.
  class EngineDisagreement < Error; end

  ROOT = File.expand_path("..", __dir__)
  GENERATOR_PATH = "scripts/stage_cases.rb"
  LATEXMATH_REPOSITORY = "https://github.com/plurimath/latexmath"
  TESTSUITE_REPOSITORY = "https://github.com/plurimath/plurimath-testsuite"
  LANGUAGES = %w[latex].freeze
  ENGINES = %i[ruby native].freeze
  DECIMAL = "."
  PRODUCER = "latexmath-raw"
  BOUNDARIES = %w[raw-tree typed-model].freeze
  PRODUCERS = { "raw-tree" => PRODUCER, "typed-model" => "latexmath-model" }.freeze
  PREFIXES = { "raw-tree" => "raw", "typed-model" => "model" }.freeze
  LML = "model/latex.lml.json"
  LML_CHECKSUMS = "model/latex.lml.checksums.txt"
  ARTIFACT = "artifacts/latex.json"
  CHECKSUMS = "artifacts/latex.checksums.txt"
  BINDING_TARGETS = %w[ruby rs ts python].freeze
  # The case keys a legacy generation-1 payload may carry. A key outside
  # this list (caller options, say) is not understood, so the run stops.
  CASE_KEYS = %w[id input input_format preprocessed expected parse_tree model error].freeze

  # --- canonical tagged form -------------------------------------------------

  module Canonical
    module_function

    # +value+ in canonical tagged form. +source+ is the grammar input the
    # slices point into, for their character offsets.
    def dump(value, source: nil)
      case value
      when nil then { "nil" => true }
      when true, false then { "bool" => value }
      when Integer then { "int" => value.to_s }
      when Symbol then { "sym" => value.to_s }
      when String then string(value)
      when Array then { "array" => value.map { |item| dump(item, source: source) } }
      when Hash
        { "hash" => value.map { |key, item| [dump(key, source: source), dump(item, source: source)] } }
      else
        return slice(value, source) if slice?(value)

        raise Error, "no canonical form for #{value.class}"
      end
    end

    # Valid UTF-8 bytes are {str:}, whatever the string's encoding label
    # (the preprocessing labels all-ASCII text US-ASCII; the bytes are the
    # same). Anything else keeps its bytes as hex with its encoding.
    def string(value)
      utf8 = value.dup.force_encoding(Encoding::UTF_8)
      return { "str" => utf8 } if utf8.valid_encoding?

      { "bytes" => value.unpack1("H*"), "encoding" => value.encoding.name }
    end

    def slice?(value)
      value.class.name.to_s.end_with?("::Slice") && value.respond_to?(:offset)
    end

    # Parsanol's Slice#offset is a byte offset into the grammar input on both
    # engines.
    def slice(value, source)
      text = value.to_s.dup.force_encoding(Encoding::UTF_8)
      raise Error, "slice text is not valid UTF-8" unless text.valid_encoding?

      node = { "slice" => text, "byte_offset" => value.offset }
      if source
        node["char_offset"] = source.byteslice(0, value.offset).force_encoding(Encoding::UTF_8).scrub.length
      end
      node
    end
  end

  # --- typed model in canonical tagged form --------------------------------

  module ModelForm
    module_function

    def model_class?(type)
      type.is_a?(Class) && type < Lutaml::Model::Serializable
    end

    # The tagged node of +klass+ from its bound data +data+ (attribute name
    # => plain data). +path+ names the place for error messages.
    def node(klass, data, path = "")
      raise Error, "#{path}/: #{klass} data is a #{data.class}, not a Hash" unless data.is_a?(Hash)

      attributes = klass.attributes
      unknown = data.keys.map(&:to_s) - attributes.keys.map(&:to_s)
      raise Error, "#{path}/: #{klass} has no attribute #{unknown.join(', ')}" unless unknown.empty?

      instance = nil
      fields = attributes.filter_map do |name, attribute|
        symbol_field = klass <= Latexmath::Model::MathSymbol && %i[value kind].include?(name)
        value = if attribute.derived? || symbol_field
                  (instance ||= klass.new(data)).public_send(name)
                else
                  data.fetch(name.to_s) { data[name] }
                end
        next if value.nil?

        [name.to_s, field(attribute, value, "#{path}/#{name}")]
      end
      { "node" => klass.name, "fields" => fields }
    end

    def field(attribute, value, path)
      return value(attribute.type, value, path) unless attribute.collection?
      raise Error, "#{path}: a collection holds a #{value.class}" unless value.is_a?(Array)

      { "array" => value.each_with_index.map { |item, i| value(attribute.type, item, "#{path}/#{i}") } }
    end

    def value(type, value, path)
      return node(type, value, path) if model_class?(type)
      return Canonical.string(value) if type == Lutaml::Model::Type::String && value.is_a?(String)

      raise Error, "#{path}: #{value.class} for a #{type} attribute"
    end

    # The same tagged form read from a built model through its declared
    # attributes.
    def walk(value)
      case value
      when Lutaml::Model::Serializable
        fields = value.class.attributes.filter_map do |name, _attribute|
          child = value.public_send(name)
          [name.to_s, walk(child)] unless child.nil?
        end
        { "node" => value.class.name, "fields" => fields }
      when Array then { "array" => value.map { |item| walk(item) } }
      when String then Canonical.string(value)
      else raise Error, "no canonical form for #{value.class} in the model"
      end
    end
  end

  # --- reading the source generation -----------------------------------------

  Case = Struct.new(:id, :input, :payload, :legacy, keyword_init: true)

  module Source
    module_function

    def sha256(path)
      Digest::SHA256.file(path).hexdigest
    end

    # The snapshot digest of docs/stage-corpus-contract.adoc.
    def snapshot_digest(dir)
      files = Dir.glob("**/*", File::FNM_DOTMATCH, base: dir).reject { |rel| File.directory?(File.join(dir, rel)) }
      raise Error, "#{dir} is empty" if files.empty?

      lines = files.sort_by(&:b).map do |rel|
        path = File.join(dir, rel)
        raise Error, "#{rel}: symlinks are not allowed" if File.symlink?(path)

        "#{sha256(path)}  #{rel}\n"
      end
      "sha256:#{Digest::SHA256.hexdigest(lines.join)}"
    end

    def ledger_entry(testsuite, language, generation)
      path = File.join(testsuite, "generations", "#{language}.yaml")
      ledger = YAML.safe_load_file(path)
      raise Error, "#{path}: not a plurimath-stage/ledger/1" unless ledger["schema"] == "plurimath-stage/ledger/1"

      entry = ledger.fetch("entries").find { |e| e["generation"] == generation }
      raise Error, "#{path} has no generation #{generation}" unless entry

      entry
    end

    # [entry, generation dir, payload paths in provenance order]
    def verify(testsuite, language, generation, digest)
      entry = ledger_entry(testsuite, language, generation)
      expected_path = format("stages/%<language>s/generations/%<generation>06d", language: language,
                                                                                generation: generation)
      raise Error, "ledger path #{entry['path']} is not #{expected_path}" unless entry["path"] == expected_path

      dir = File.join(testsuite, expected_path)
      actual = snapshot_digest(dir)
      unless actual == entry["snapshot_digest"]
        raise Error, "#{expected_path}: snapshot digest #{actual} does not match the ledger's #{entry['snapshot_digest']}"
      end
      raise Error, "#{expected_path}: snapshot digest #{actual} is not the expected #{digest}" unless actual == digest

      provenance = YAML.safe_load_file(File.join(dir, "provenance.yaml"))
      unless provenance["language"] == language && provenance["generation"] == generation
        raise Error, "#{expected_path}/provenance.yaml names another generation"
      end

      payloads = provenance.fetch("payloads").map { |p| p.fetch("path") }
      [entry, dir, payloads]
    end

    def cases(dir, payload_paths)
      payload_paths.flat_map do |rel|
        doc = YAML.safe_load_file(File.join(dir, rel))
        doc.fetch("cases").map do |row|
          unknown = row.keys - CASE_KEYS
          raise Error, "#{rel} #{row['id']}: unsupported case keys #{unknown.join(', ')}" unless unknown.empty?

          input = row.fetch("input")
          raise Error, "#{rel} #{row['id']}: input is not a string" unless input.is_a?(String)

          Case.new(id: row.fetch("id"), input: input, payload: rel,
                   legacy: row.slice("preprocessed", "parse_tree", "error"))
        end
      end
    end
  end

  # --- parsing ----------------------------------------------------------------

  module Parse
    module_function

    # [outcome in payload form, the RawParser result or the ParseError] of
    # +input+ on +engine+.
    def outcome(input, engine)
      result = Latexmath::RawParser.parse(input, decimal: DECIMAL, engine: engine)
      unless result.engine == engine
        raise Error, "#{input.inspect}: asked for the #{engine} engine, #{result.engine} ran"
      end

      text = result.text.dup.force_encoding(Encoding::UTF_8)
      [{ "preprocessed" => Canonical.string(result.text), "tree" => Canonical.dump(result.tree, source: text) },
       result]
    rescue Latexmath::NestingTooDeep => e
      raise Error, "#{input.inspect}: #{engine} engine: #{e.message}"
    rescue Latexmath::ParseError => e
      unless Latexmath.last_engine == engine
        raise Error, "#{input.inspect}: asked for the #{engine} engine, #{Latexmath.last_engine} ran"
      end

      [{ "refusal" => { "category" => "parse_error", "byte_offset" => e.byte_offset } }, e]
    end

    # [outcome in payload form, the built Document or the ParseError] of
    # +input+ through Latexmath.parse on +engine+. The tree is written from
    # the bound model data and must equal a walk of the built Document.
    def model_outcome(input, engine)
      text = Latexmath::RawParser.normalize_input(input)
      preprocessed = Latexmath::Preprocessor.call(text)
      data = { "decimal" => DECIMAL }
      unless preprocessed.empty?
        result = Latexmath::RawParser.parse(input, decimal: DECIMAL, engine: engine)
        unless result.engine == engine
          raise Error, "#{input.inspect}: asked for the #{engine} engine, #{result.engine} ran"
        end

        data["expression"] = result.model
      end
      document = Latexmath.parse(input, decimal: DECIMAL, engine: engine)
      tree = ModelForm.node(Latexmath::Model::Document, data)
      unless ModelForm.walk(document) == tree
        raise Error, "#{input.inspect}: #{engine} engine: the built model differs from its bound data"
      end

      [{ "preprocessed" => Canonical.string(preprocessed), "tree" => tree }, document]
    rescue Latexmath::NestingTooDeep => e
      raise Error, "#{input.inspect}: #{engine} engine: #{e.message}"
    rescue Latexmath::ParseError => e
      unless Latexmath.last_engine == engine
        raise Error, "#{input.inspect}: asked for the #{engine} engine, #{Latexmath.last_engine} ran"
      end

      [{ "refusal" => { "category" => "parse_error", "byte_offset" => e.byte_offset } }, e]
    end
  end

  # --- legacy comparison --------------------------------------------------------

  module Legacy
    module_function

    # The tree as the legacy corpus generator serialized it: slices and
    # symbols as strings, hash keys as strings in sorted order.
    def plain(value)
      case value
      when Hash then value.to_h { |k, v| [k.to_s, plain(v)] }.sort.to_h
      when Array then value.map { |v| plain(v) }
      when Symbol then value.to_s
      when nil, true, false, Integer, String then value
      else
        Canonical.slice?(value) ? value.to_s.dup.force_encoding(Encoding::UTF_8) : value
      end
    end

    # Differences between the gem's +outcome+ (a RawParser result or a
    # ParseError) and the legacy +row+.
    def differences(row, outcome)
      legacy = row.legacy
      out = []
      if outcome.is_a?(Latexmath::ParseError)
        if legacy.key?("error")
          index = legacy.dig("error", "index")
          unless index == outcome.grammar_char_offset
            out << "refusal index #{index.inspect} vs grammar char offset #{outcome.grammar_char_offset.inspect}"
          end
        else
          out << "legacy parsed, gem refused"
        end
      else
        out << "legacy refused, gem parsed" if legacy.key?("error")
        text = outcome.text.dup.force_encoding(Encoding::UTF_8)
        out << "preprocessed differs" if legacy.key?("preprocessed") && legacy["preprocessed"] != text
        out << "parse_tree differs" if legacy.key?("parse_tree") && legacy["parse_tree"] != plain(outcome.tree)
      end
      out
    end
  end

  # --- producer identity ------------------------------------------------------

  module Identity
    module_function

    def git(dir, *args)
      out, status = Open3.capture2("git", "-C", dir, *args)
      raise Error, "git #{args.join(' ')} failed in #{dir}" unless status.success?

      out.strip
    end

    def file(repository, commit, root, rel)
      { "repository" => repository, "commit" => commit, "path" => rel,
        "sha256" => Source.sha256(File.join(root, rel)) }
    end

    # artifacts/latex.checksums.txt: "key value..." lines; the binding
    # lines ("bindings <target> checksum <digest>") are keyed by target.
    def checksums
      File.readlines(File.join(ROOT, CHECKSUMS), chomp: true).each_with_object({ "bindings" => {} }) do |line, h|
        next if line.start_with?("#") || line.strip.empty?

        key, *rest = line.split
        if key == "bindings"
          h["bindings"][rest[0]] = rest[2]
        else
          h[key] = rest
        end
      end
    end

    # Gemfile.lock is not committed in latexmath: it is the lock this run
    # resolved, so its digest and resolved versions are recorded.
    def lockfile(path)
      { "path" => "Gemfile.lock", "committed" => false, "sha256" => Source.sha256(path),
        "bundler" => Bundler::VERSION,
        "resolved" => Bundler.load.specs.sort_by(&:name).to_h { |spec| [spec.name, spec.version.to_s] } }
    end

    def dependencies
      spec = Gem::Specification.load(File.join(ROOT, "latexmath.gemspec"))
      spec.runtime_dependencies.map(&:name).sort.to_h do |name|
        loaded = Gem.loaded_specs[name]
        raise Error, "runtime dependency #{name} is not loaded" unless loaded

        [name, loaded.version.to_s]
      end
    end

    # The committed LML export the typed-model rows' classes are declared in.
    def lml(commit)
      export = JSON.parse(File.read(File.join(ROOT, LML)))
      documents = File.readlines(File.join(ROOT, LML_CHECKSUMS), chomp: true)
                      .map(&:split).find { |key, _| key == LML }
      raise Error, "#{LML_CHECKSUMS} has no line for #{LML}" unless documents

      checksum = "sha256:#{Source.sha256(File.join(ROOT, LML))}"
      raise Error, "#{LML} does not match #{LML_CHECKSUMS}" unless documents[1] == checksum

      { "format" => export.fetch("format"), "root" => export.fetch("root"),
        "checksum" => checksum, "models" => export.fetch("models").size,
        "export" => file(LATEXMATH_REPOSITORY, commit, ROOT, LML),
        "checksums" => file(LATEXMATH_REPOSITORY, commit, ROOT, LML_CHECKSUMS) }
    end

    def producer(testsuite:, testsuite_commit:, payload_paths:, generation_dir:, generation:, digest:,
                 boundary: "raw-tree")
      dirty = git(ROOT, "status", "--porcelain", "--untracked-files=no")
      raise Error, "the latexmath checkout has uncommitted changes:\n#{dirty}" unless dirty.empty?

      commit = git(ROOT, "rev-parse", "HEAD")
      lock = File.join(ROOT, "Gemfile.lock")
      raise Error, "Gemfile.lock not found; run bundle install" unless File.file?(lock)

      sums = checksums
      compiler_version = sums.fetch("compiler_version").first
      unless Parsanol::VERSION == compiler_version
        raise Error, "parsanol #{Parsanol::VERSION} is loaded; the artifact was compiled with #{compiler_version}"
      end

      envelope = JSON.parse(File.read(File.join(ROOT, ARTIFACT)), max_nesting: false)
      rel_dir = generation_dir.delete_prefix("#{testsuite}/")
      {
        "kind" => "stage-gem",
        "repository" => LATEXMATH_REPOSITORY,
        "commit" => commit,
        "version" => Latexmath::VERSION,
        "generator" => file(LATEXMATH_REPOSITORY, commit, ROOT, GENERATOR_PATH),
        "inputs" => payload_paths.map do |rel|
          file(TESTSUITE_REPOSITORY, testsuite_commit, testsuite, "#{rel_dir}/#{rel}")
        end,
        "environment" => {
          "ruby" => { "engine" => RUBY_ENGINE, "version" => RUBY_VERSION },
          "lockfile" => lockfile(lock),
          "dependencies" => dependencies,
          "compiler" => {
            "name" => "parsanol",
            "version" => compiler_version,
            "edition" => sums.fetch("edition").first,
            "artifact_checksum" => sums.fetch("artifact_checksum").first,
            "source_hash" => sums.fetch("source_hash").first,
            "unicode_tables" => envelope["unicode_tables"],
            "artifact" => file(LATEXMATH_REPOSITORY, commit, ROOT, ARTIFACT),
            "checksums" => file(LATEXMATH_REPOSITORY, commit, ROOT, CHECKSUMS),
          },
          "binding" => {
            "binding_version" => envelope["binding_version"],
            "artifacts" => BINDING_TARGETS.map do |target|
              file(LATEXMATH_REPOSITORY, commit, ROOT, "artifacts/latex.bindings.#{target}.json")
                .merge("target" => target, "checksum" => sums.fetch("bindings").fetch(target))
            end,
          },
          "lml" => (boundary == "typed-model" ? lml(commit) : nil),
        },
        "semantic_boundary" => boundary,
        "configuration" => {
          "parser" => boundary == "typed-model" ? "Latexmath.parse" : "Latexmath::RawParser.parse",
          "decimal" => DECIMAL,
          "engines" => ENGINES.map(&:to_s),
          "engine_agreement" => "required",
          "source_generation" => { "language" => "latex", "generation" => generation, "snapshot_digest" => digest },
        },
      }
    end
  end

  # --- writing ------------------------------------------------------------------

  module Writer
    module_function

    def group(source_rel, boundary = "raw-tree")
      "#{PREFIXES.fetch(boundary)}-#{File.basename(source_rel, '.yaml')}"
    end

    def payload(group, rows, boundary = "raw-tree")
      source = group.delete_prefix("#{PREFIXES.fetch(boundary)}-")
      description =
        if boundary == "typed-model"
          "Typed models (Latexmath::Model::Document) from Latexmath.parse for the rows of #{source}.yaml, " \
            "the same on the Ruby and native engines. Each object is its model class (#{LML}) with its set " \
            "fields in declaration order; nil fields are left out. A refusal's byte_offset is in the caller's input."
        else
          "Raw grammar trees from Latexmath::RawParser.parse for the rows of " \
            "#{source}.yaml, the same on the Ruby and native engines. " \
            "A refusal's byte_offset is in the caller's input."
        end
      {
        "schema" => "plurimath-stage/latex/cases/1",
        "group" => group,
        "description" => description,
        "boundary" => boundary,
        "cases" => rows,
      }
    end

    def text(group, doc)
      "# LaTeX #{doc.fetch('boundary')} stage cases: #{group}.\n" \
        "# Written by scripts/stage_cases.rb in plurimath/latexmath. Do not edit.\n" \
        "# Provenance lives in this generation's provenance.yaml.\n" +
        YAML.dump(doc, line_width: -1)
    end
  end

  module_function

  # Runs every case on both engines. Returns [rows by source payload,
  # disagreements, legacy differences].
  def generate(cases, log: $stderr, boundary: "raw-tree")
    model = boundary == "typed-model"
    rows = Hash.new { |h, k| h[k] = [] }
    disagreements = []
    legacy = []
    cases.each_with_index do |row, index|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      results = ENGINES.to_h do |engine|
        [engine, model ? Parse.model_outcome(row.input, engine) : Parse.outcome(row.input, engine)]
      end
      log.puts format("%<n>d/%<total>d %<id>s %<s>.1fs", n: index + 1, total: cases.size, id: row.id,
                                                          s: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
      outcomes = results.transform_values(&:first)
      if outcomes.values.uniq.size != 1
        disagreements << { "id" => row.id, "input" => row.input, "outcomes" => outcomes.transform_keys(&:to_s) }
        next
      end

      diffs = model ? [] : Legacy.differences(row, results[:native].last)
      legacy << { "id" => row.id, "differences" => diffs } unless diffs.empty?
      rows[row.payload] << { "id" => "#{row.id}.#{PREFIXES.fetch(boundary)}", "input" => Canonical.string(row.input),
                             "options" => { "decimal" => DECIMAL },
                             "expected" => outcomes[:native] }
    end
    [rows, disagreements, legacy]
  end

  def run(testsuite:, language:, generation:, digest:, output:, report: nil, log: $stderr, boundary: "raw-tree")
    raise Error, "unsupported language #{language.inspect} (#{LANGUAGES.join(', ')})" unless LANGUAGES.include?(language)
    raise Error, "unknown boundary #{boundary.inspect} (#{BOUNDARIES.join(', ')})" unless BOUNDARIES.include?(boundary)
    raise Error, "the native engine is not available" unless Latexmath::Engine.native_available?

    testsuite = File.expand_path(testsuite)
    _entry, dir, payload_paths = Source.verify(testsuite, language, generation, digest)
    testsuite_commit = Identity.git(testsuite, "rev-parse", "HEAD")
    cases = Source.cases(dir, payload_paths)
    log.puts "#{cases.size} cases from #{payload_paths.size} payloads of #{language} generation #{generation}"

    rows, disagreements, legacy = generate(cases, log: log, boundary: boundary)
    summary = { "cases" => cases.size, "engine_disagreements" => disagreements,
                "legacy_differences" => legacy }
    write_report(report, summary) if report
    unless disagreements.empty?
      raise EngineDisagreement, "the Ruby and native engines disagree on #{disagreements.size} rows: " \
                                "#{disagreements.map { |d| d['id'] }.join(', ')}"
    end

    payloads = write_payloads(output, payload_paths, rows, boundary)
    producer = Identity.producer(testsuite: testsuite, testsuite_commit: testsuite_commit,
                                 payload_paths: payload_paths, generation_dir: dir,
                                 generation: generation, digest: digest, boundary: boundary)
    fragment = { "producers" => { PRODUCERS.fetch(boundary) => producer }, "payloads" => payloads }
    File.write(File.join(output, "provenance-fragment.yaml"), YAML.dump(fragment, line_width: -1))
    log.puts "wrote #{payloads.size} payloads, #{payloads.sum { |p| p['rows'].size }} rows; " \
             "#{legacy.size} rows differ from the legacy generation"
    summary.merge("payloads" => payloads)
  end

  def write_report(path, summary)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "#{JSON.pretty_generate(summary, max_nesting: false)}\n")
  end

  def write_payloads(output, payload_paths, rows, boundary = "raw-tree")
    dir = File.join(output, "payloads")
    FileUtils.mkdir_p(dir)
    payload_paths.filter_map do |rel|
      next if rows[rel].empty?

      group = Writer.group(rel, boundary)
      path = File.join(dir, "#{group}.yaml")
      File.write(path, Writer.text(group, Writer.payload(group, rows[rel], boundary)))
      { "path" => "payloads/#{group}.yaml", "bytes" => File.size(path), "sha256" => Source.sha256(path),
        "producer" => PRODUCERS.fetch(boundary), "source" => { "relation" => "generated", "file" => nil },
        "rows" => rows[rel].map { |r| r["id"] } }
    end.sort_by { |p| p["path"].b }
  end

  def main(argv)
    options = { language: "latex" }
    OptionParser.new do |o|
      o.banner = "usage: scripts/stage_cases.rb --testsuite PATH --generation N --digest sha256:HEX --output DIR"
      o.on("--testsuite PATH") { |v| options[:testsuite] = v }
      o.on("--language NAME") { |v| options[:language] = v }
      o.on("--generation N", Integer) { |v| options[:generation] = v }
      o.on("--digest DIGEST") { |v| options[:digest] = v }
      o.on("--output DIR") { |v| options[:output] = v }
      o.on("--report FILE") { |v| options[:report] = v }
      o.on("--boundary NAME", BOUNDARIES) { |v| options[:boundary] = v }
    end.parse!(argv)
    missing = %i[testsuite generation digest output] - options.keys
    raise OptionParser::MissingArgument, missing.map { |k| "--#{k}" }.join(", ") unless missing.empty?

    run(**options)
    0
  rescue OptionParser::ParseError => e
    warn e.message
    2
  rescue Error => e
    warn "stage_cases: #{e.message}"
    1
  end
end

if $PROGRAM_NAME == __FILE__
  $LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
  require "latexmath/parser"
  exit LatexmathStageCases.main(ARGV)
end
