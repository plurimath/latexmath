# frozen_string_literal: true

# Plurimath's LaTeX grammar (Parsanol Ruby DSL) -> grammars/latex.parg
#
# Usage:
#   ruby scripts/generate_grammar.rb            write grammars/latex.parg from
#                                               data/latex-atoms.json
#   ruby scripts/generate_grammar.rb --check    exit 1 if grammars/latex.parg
#                                               differs from a fresh generation
#   BUNDLE_GEMFILE=<oracle>/.latexmath-oracle/Gemfile \
#     bundle exec ruby scripts/generate_grammar.rb --export --oracle <oracle> [--check]
#                                               export data/latex-atoms.json
#                                               again from the pinned Plurimath
#                                               checkout, then generate (with
#                                               --check: compare both files)
#
# Two phases, as in plurimath/amath:
#
#   export    the one-time provenance step. It needs the pinned Plurimath
#             checkout (scripts/oracle/pins.yml) and its locked bundle
#             (scripts/oracle/setup.rb). For each decimal marker Plurimath
#             supports, a forked child sets a locale with that marker, builds
#             Plurimath::Latex::Parse.new.root and walks the atom graph: every
#             Entity becomes a rule, every other atom is transcribed inline. A
#             fork per marker is required: the legacy grammar caches atoms in
#             class variables (@@expression, @@new_hash), so a second Parse in
#             the same process reuses the first one's atoms and marker. Rules
#             whose graph is the same under every marker are stored once; the
#             others are stored per marker.
#   generate  stdlib only, and a pure function of data/latex-atoms.json (no
#             timestamps, no hash-order dependence). The build and the gem never
#             load Plurimath.

require "digest"
require "json"
require "open3"
require "optparse"

ROOT = File.expand_path("..", __dir__)
DATA = File.join(ROOT, "data/latex-atoms.json")
OUT = File.join(ROOT, "grammars/latex.parg")
FORMAT = "latexmath-atoms/v1"

# Decimal marker -> entry name (and rule suffix). A marker without a name
# stops the export.
MARKER_NAMES = { "." => "dot", "," => "comma", "\u066B" => "arabic" }.freeze

# The capture that carries the legacy tree through the declared bindings.
TREE_CAPTURE = "latex_tree"

module Export
  module_function

  def run(oracle)
    require_relative "oracle/lib/latexmath_oracle/oracle_env"
    env = LatexmathOracle::OracleEnv.new(oracle)
    env.verify!
    $LOAD_PATH.unshift(File.join(env.checkout, "lib"))
    require "plurimath"

    graphs = markers.map { |marker, locale| capture(marker, locale) }
    names = graphs.map { |g| g["rules"].map(&:first) }
    abort "rule order differs between markers: #{names.map(&:size)}" unless names.uniq.size == 1

    rules = names.first.map do |name|
      exprs = graphs.to_h { |g| [g["name"], g["rules"].assoc(name).last] }
      [name, exprs.values.uniq.size == 1 ? { "*" => exprs.values.first } : exprs]
    end
    roots = graphs.map { |g| g["root"] }.uniq
    abort "roots differ between markers: #{roots.inspect}" unless roots.size == 1

    {
      "format" => FORMAT,
      "oracle" => {
        "repository" => env.pins.dig("plurimath", "repository"),
        "commit" => env.commit,
        "lib_tree" => git(env.checkout, "rev-parse", "#{env.commit}:lib"),
        "ruby" => RUBY_VERSION,
        "parsanol" => Gem.loaded_specs.fetch("parsanol").version.to_s,
        "latex_sources" => env.pins.dig("plurimath", "latex_sources").keys.to_h do |file|
          [file, "sha256:#{Digest::SHA256.file(File.join(env.checkout, file)).hexdigest}"]
        end,
      },
      "root" => roots.first,
      "markers" => graphs.map { |g| g.slice("name", "decimal", "locale", "encoded", "atoms") },
      "rules" => rules,
    }
  end

  def git(dir, *args)
    out, status = Open3.capture2("git", "-C", dir, *args)
    abort "git #{args.join(' ')} failed in #{dir}" unless status.success?
    out.strip
  end

  # [marker, locale] pairs: the default marker (no locale) first, then every
  # other marker of SupportedLocales::LOCALES with the first locale using it.
  def markers
    list = [[Plurimath::Configuration::DEFAULT_DECIMAL, nil]]
    Plurimath::Formatter::SupportedLocales::LOCALES.each do |locale, symbols|
      decimal = symbols[:decimal]
      list << [decimal, locale.to_s] unless decimal.nil? || list.any? { |m, _| m == decimal }
    end
    list.each { |m, _| abort "decimal marker #{m.inspect} has no entry name" unless MARKER_NAMES.key?(m) }
    list
  end

  def capture(marker, locale)
    reader, writer = IO.pipe
    pid = fork do
      reader.close
      Plurimath.configuration.locale = locale&.to_sym
      unless Plurimath.configuration.decimal == marker
        abort "locale #{locale.inspect} gives decimal #{Plurimath.configuration.decimal.inspect}"
      end
      walker = Walker.new
      root = walker.ref(Plurimath::Latex::Parse.new.root)
      writer.write(JSON.generate(
                     "name" => MARKER_NAMES.fetch(marker), "decimal" => marker, "locale" => locale,
                     "encoded" => Plurimath::Utility.string_to_html_entity(marker.dup),
                     "atoms" => walker.count, "root" => root.last, "rules" => walker.rules,
                   ))
      writer.close
      exit!(0)
    end
    writer.close
    payload = reader.read
    _, status = Process.waitpid2(pid)
    abort "export child for #{marker.inspect} failed (#{status.inspect})" unless status.success? && !payload.empty?
    JSON.parse(payload)
  end

  # Transcribes the live atom graph. Entities become named rules (in first-
  # visit pre-order); every other atom is written inline, so a shared
  # non-Entity atom is written once per use.
  class Walker
    attr_reader :count

    def initialize
      @rules = {}
      @ids = {}
      @count = 0
      @seen = {}
    end

    def rules = @rules.to_a

    def ref(entity)
      name = entity.name.to_s
      if (id = @ids[name])
        abort "two Entity atoms are named #{name}" unless id == entity.object_id
        return ["ref", name]
      end
      @ids[name] = entity.object_id
      @rules[name] = nil
      @rules[name] = expr(entity.parslet)
      ["ref", name]
    end

    def expr(atom)
      unless @seen[atom.object_id]
        @seen[atom.object_id] = atom
        @count += 1
      end
      case atom
      when Parsanol::Atoms::Entity then ref(atom)
      when Parsanol::Atoms::Str then ["str", atom.str]
      when Parsanol::Atoms::Re then ["re", atom.match]
      when Parsanol::Atoms::Sequence then ["seq", *atom.parslets.map { |a| expr(a) }]
      when Parsanol::Atoms::Alternative then ["alt", *atom.alternatives.map { |a| expr(a) }]
      when Parsanol::Atoms::Repetition then ["rep", atom.min, atom.max, atom.result_tag.to_s, expr(atom.parslet)]
      when Parsanol::Atoms::Named then ["as", atom.name.to_s, expr(atom.parslet)]
      when Parsanol::Atoms::Lookahead then ["look", atom.positive, expr(atom.bound_parslet)]
      else abort "atom #{atom.class} has no PARG transcription"
      end
    end
  end

  # One rule per line keeps the data file diffable.
  def dump(data)
    head = data.except("rules")
    lines = data["rules"].map { |rule| "    #{JSON.generate(rule)}" }
    "#{JSON.pretty_generate(head).delete_suffix("\n}")},\n  \"rules\": [\n#{lines.join(",\n")}\n  ]\n}\n"
  end
end

class Generator
  # Parslet regexp -> PARG character class. The native engine runs these
  # through Rust's regex crate, so the sets below are the ones it matches.
  # A pattern missing here stops generation.
  CLASSES = {
    "[0-9]" => [nil, "%x30-39"],
    "[0-7]" => [nil, "%x30-37"],
    "[01]" => [nil, "%x30-31"],
    " " => [nil, "%x20"],
    "." => ["any_char", "%x00-10FFFF"],
    "[0-9a-fA-F]" => ["hex_digit", "%x30-39 / %x41-46 / %x61-66"],
    "[a-zA-Z]" => ["ascii_letter", "%x41-5A / %x61-7A"],
    "[^}]" => ["not_rbrace", "%x00-7C / %x7E-10FFFF"],
    "(?-mix:\\s)" => ["white_space",
                      "%x09-0D / %x20 / %x85 / %xA0 / %x1680 / %x2000-200A / %x2028-2029 / %x202F / %x205F / %x3000"],
  }.freeze

  # Capture names PARG cannot spell (`as` takes an identifier). The runtime
  # renames them back (Latexmath::Configuration::CAPTURE_RENAMES).
  CAPTURE_RENAMES = { "\\\\" => "row_break" }.freeze

  KEYWORDS = %w[grammar as alt from_table column bindings render derive preprocess entry table_lookup
                custom state set switch skip until atomic capture use glue resync].freeze

  # Rule-splitting limits (see the header notes). Splitting only moves
  # branches into rules of their own: an Entity wrapper and the
  # associativity of PEG choice leave every tree unchanged.
  HOIST = 32   # an inline (non-rule-level) alternative longer than this becomes a rule
  CHUNK = 16   # a rule-level alternative longer than this becomes a tree of rules
  MIN_RUN = 4  # shortest run of marker-independent branches shared across markers

  def initialize(data_bytes)
    @data_bytes = data_bytes
    @data = JSON.parse(data_bytes)
    abort "unsupported data format #{@data['format']}" unless @data["format"] == FORMAT
    @rules = @data["rules"].to_h
    @markers = @data["markers"].map { |m| m["name"] }
    @specialised = specialised_rules.to_h { |n| [n, true] }
    @plurimath_specialised = @specialised.keys
    @defined = {}
    @counters = Hash.new(0)
    @helpers = {}
    check_names!
  end

  def generate
    body = @rules.flat_map { |name, exprs| define(name, exprs) }
    helpers = @helpers.sort.map { |name, (src, rhs)| "  # match(#{src.inspect})\n  #{name} = #{rhs}" }
    out = [header, "", 'grammar Latex version "0.1.0" {', *body, "",
           "  # ---- character classes (no Plurimath rule of their own) ----", *helpers, "",
           "  # ---- the tree capture each entry starts from ----", *tree_rules, "}", "",
           *entries, "", *bindings].join("\n")
    bad = out.each_line.with_index(1).reject { |l, _| l.ascii_only? }.map(&:last)
    abort "generated grammar is not pure ASCII (lines #{bad.first(5).join(', ')})" unless bad.empty?
    "#{out}\n"
  end

  private

  def tree_rule(marker) = "#{TREE_CAPTURE}__#{marker}"

  # The legacy root under one capture, so that the declared bindings can
  # carry the whole raw tree (a `raw` binding) without naming its fields.
  def tree_rules
    @markers.map { |m| "  #{tree_rule(m)} = (#{rule_name(@data['root'], m)}) as #{TREE_CAPTURE}" }
  end

  def entries = @markers.map { |m| "entry #{m}: #{tree_rule(m)}" }

  def bindings
    @markers.flat_map do |m|
      ["bindings #{tree_rule(m)} {", "  #{TREE_CAPTURE} -> #{TREE_CAPTURE} (raw)", "}", ""]
    end[0..-2]
  end

  # The lines of one rule (once, or once per marker when specialised)
  # followed by the rules split out of it.
  def define(name, exprs)
    abort "rule #{name} defined twice" if @defined[name]
    @defined[name] = true
    extra = []
    exprs = exprs.transform_values { |e| hoist_nested(name, e, extra, exprs.key?("*"), top: true) }
    expr = exprs["*"]
    if expr && expr.first == "alt" && expr.size - 1 > CHUNK
      branches = expr.drop(1)
      branches = share_runs(name, branches, extra) if dependent?(expr)
      branches = chunk(name, branches, extra) while branches.size > CHUNK
      exprs = { "*" => ["alt", *branches] }
    end
    markers = @specialised[name] ? @markers : [nil]
    markers.map { |m| format_rule(rule_name(name, m), exprs[m] || exprs.fetch("*"), m) } + extra
  end

  def helper(name, kind, expr, extra)
    @counters[[name, kind]] += 1
    helper = "#{name}_#{kind}#{@counters[[name, kind]]}"
    abort "helper rule #{helper} collides with a Plurimath rule" if @rules.key?(helper)
    @specialised[helper] = true if dependent?(expr)
    extra.concat(define(helper, { "*" => expr }))
    ["ref", helper]
  end

  # Maximal runs of MIN_RUN or more marker-independent branches of a
  # specialised rule move into one shared rule <rule>_run<k>.
  def share_runs(name, branches, extra)
    out = []
    run = []
    flush = lambda do
      run.size >= MIN_RUN ? out << helper(name, "run", ["alt", *run], extra) : out.concat(run)
      run = []
    end
    branches.each do |branch|
      if dependent?(branch)
        flush.call
        out << branch
      else
        run << branch
      end
    end
    flush.call
    out
  end

  # Consecutive groups of CHUNK branches become rules <rule>_part<k>.
  def chunk(name, branches, extra)
    branches.each_slice(CHUNK).map do |group|
      group.size == 1 ? group.first : helper(name, "part", ["alt", *group], extra)
    end
  end

  # Inline alternatives longer than HOIST become rules <rule>_alt<k>.
  def hoist_nested(name, expr, extra, shared, top: false)
    case expr.first
    when "alt"
      kids = expr.drop(1).map { |e| hoist_nested(name, e, extra, shared) }
      if !top && kids.size > HOIST
        abort "#{name}: cannot hoist from a per-marker rule body" unless shared
        return helper(name, "alt", ["alt", *kids], extra)
      end
      ["alt", *kids]
    when "seq" then ["seq", *expr.drop(1).map { |e| hoist_nested(name, e, extra, shared) }]
    when "rep" then [*expr[0, 4], hoist_nested(name, expr[4], extra, shared)]
    when "as", "look" then [expr[0], expr[1], hoist_nested(name, expr[2], extra, shared)]
    else expr
    end
  end

  def dependent?(expr) = refs(expr).any? { |r| @specialised[r] }

  # Rules whose graph differs between markers, closed over "references a
  # specialised rule".
  def specialised_rules
    set = @rules.reject { |_, exprs| exprs.key?("*") }.keys
    loop do
      added = @rules.keys.reject { |n| set.include?(n) }.select do |n|
        @rules[n].values.any? { |e| refs(e).any? { |r| set.include?(r) } }
      end
      break if added.empty?

      set.concat(added)
    end
    set
  end

  def refs(expr, acc = [])
    case expr.first
    when "ref" then acc << expr[1]
    when "seq", "alt" then expr.drop(1).each { |e| refs(e, acc) }
    when "rep" then refs(expr[4], acc)
    when "as", "look" then refs(expr[2], acc)
    end
    acc
  end

  def check_names!
    taken = @rules.keys + CLASSES.values.filter_map(&:first) + @markers.map { |m| tree_rule(m) }
    abort "generated rule names collide with Plurimath rules" unless taken.uniq.size == taken.size
    bad = @rules.keys.select { |n| KEYWORDS.include?(n) || n !~ /\A[A-Za-z_][A-Za-z0-9_]*\z/ }
    abort "rule names PARG cannot spell: #{bad.join(', ')}" unless bad.empty?
    used = []
    @rules.each_value { |exprs| exprs.each_value { |e| captures(e, used) } }
    abort "the legacy grammar already captures #{TREE_CAPTURE}" if used.include?(TREE_CAPTURE)
    clash = CAPTURE_RENAMES.values & used
    abort "capture renames collide with legacy captures: #{clash.join(', ')}" unless clash.empty?
  end

  def captures(expr, acc)
    case expr.first
    when "seq", "alt" then expr.drop(1).each { |e| captures(e, acc) }
    when "rep" then captures(expr[4], acc)
    when "look" then captures(expr[2], acc)
    when "as"
      acc << expr[1]
      captures(expr[2], acc)
    end
    acc
  end

  def rule_name(name, marker)
    @specialised[name] && marker ? "#{name}__#{marker}" : name
  end

  def format_rule(lhs, expr, marker)
    if expr.first == "alt"
      branches = expr.drop(1).map { |e| emit(e, marker, :alt) }
      line = "  #{lhs} = #{branches.join(' / ')}"
      return line if line.gsub(/__(?:#{@markers.join('|')})\b/, "").size <= 140 && branches.size <= 6

      "  #{lhs} = {\n      #{branches.join("\n    / ")}\n  }"
    else
      "  #{lhs} = #{emit(expr, marker, :alt)}"
    end
  end

  # ctx: :alt (a choice branch or a rule body), :seq (an element of a
  # sequence) or :primary (operand of a prefix or of `as`).
  def emit(expr, marker, ctx)
    kind = expr.first
    case kind
    when "ref" then rule_name(expr[1], marker)
    when "str" then wrap(lit(expr[1]), ctx, lit_pieces(expr[1]).size > 1 ? :seq : :primary)
    when "re" then char_class(expr[1])
    when "seq"
      wrap(expr.drop(1).map { |e| emit(e, marker, :seq) }.join(" "), ctx, :seq)
    when "alt"
      "(#{expr.drop(1).map { |e| emit(e, marker, :alt) }.join(' / ')})"
    when "rep"
      _, min, max, tag, inner = expr
      body = group(inner, marker)
      if tag == "maybe"
        abort "maybe with min #{min} max #{max}" unless min.zero? && max == 1
        "[#{emit(inner, marker, :alt)}]"
      elsif min.zero? && max.nil? then "*#{body}"
      elsif max.nil? then "#{min}*#{body}"
      else "#{min}*#{max}#{body}"
      end
    when "as"
      name = CAPTURE_RENAMES.fetch(expr[1], expr[1])
      abort "capture name #{expr[1].inspect} cannot be spelled in PARG" unless name.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/)

      "#{group(expr[2], marker)} as #{name}"
    when "look"
      "#{expr[1] ? '&' : '!'}#{group(expr[2], marker)}"
    else abort "unknown IR node #{kind}"
    end
  end

  # The parenthesised operand of a prefix or of `as` (an inline
  # alternative already carries its parentheses).
  def group(expr, marker)
    text = emit(expr, marker, :alt)
    expr.first == "alt" && text.start_with?("(") ? text : "(#{text})"
  end

  # A sequence inside a sequence keeps its parentheses, so the nesting of
  # the atom graph is preserved exactly.
  def wrap(text, ctx, level)
    level == :seq && ctx != :alt ? "(#{text})" : text
  end

  def char_class(pattern)
    helper, rhs = CLASSES.fetch(pattern) { abort "regexp #{pattern.inspect} has no PARG class" }
    return rhs unless helper

    @helpers[helper] = [pattern, rhs]
    helper
  end

  def printable?(char) = char.match?(/\A[\x20-\x7E]\z/)

  # Printable ASCII as "..." (\" and \\ escaped), anything else as %x.
  def lit(str) = lit_pieces(str).join(" ")

  def lit_pieces(str)
    abort "empty literal" if str.empty?
    str.each_char.chunk_while { |a, b| printable?(a) == printable?(b) }.flat_map do |run|
      if printable?(run.first)
        ["\"#{run.join.gsub(/["\\]/) { |c| "\\#{c}" }}\""]
      else
        run.map { |c| format("%%x%02X", c.ord) }
      end
    end
  end

  def header
    o = @data["oracle"]
    marker_docs = @data["markers"].map do |m|
      "#     entry #{m['name']}: decimal #{format('U+%04X', m['decimal'].ord)}, locale #{m['locale'] || '(default)'}, " \
        "matched as #{m['encoded'].inspect} (#{m['atoms']} atoms)"
    end
    spec = @plurimath_specialised.sort.each_slice(6).map { |s| "#     #{s.join(' ')}" }
    <<~TEXT.chomp
      # GENERATED by scripts/generate_grammar.rb from data/latex-atoms.json -- do not edit.
      # Plurimath LaTeX grammar (#{o['repository']} @ #{o['commit']},
      # lib tree #{o['lib_tree']}), Plurimath::Latex::Parse, exported with
      # Ruby #{o['ruby']} / Parsanol #{o['parsanol']}.
      # data/latex-atoms.json sha256:#{Digest::SHA256.hexdigest(@data_bytes)}
      # legacy LaTeX sources:
      #{o['latex_sources'].map { |f, sum| "#   #{f} #{sum}" }.join("\n")}
      #
      # Syntax only: the grammar reproduces the raw tree of
      # Plurimath::Latex::Parse#parse(text), where text is
      # Plurimath::Latex::Parser.new(input).text (see docs/parser-contract.adoc).
      # No model and no transform.
      #
      # Transcription: every Parsanol Entity (rule) is one rule here, under its
      # Plurimath name; every other atom is written inline, mechanically:
      #   str("x")      "x"          (non-printable / non-ASCII chars as %x)
      #   a >> b        a b          a | b      a / b
      #   .as(:n)       (X) as n     .maybe     [X]
      #   .repeat       *(X)         .repeat(1) 1*(X)
      #   .absent?      !(X)         .present?  &(X)
      # Long alternatives are split into rules of their own. A rule reference
      # only adds an Entity wrapper and PEG choice is associative, so no tree
      # changes. In order:
      #   - an inline alternative of more than #{HOIST} branches becomes <rule>_alt<k>;
      #   - in a rule specialised per decimal marker (below), each maximal run
      #     of #{MIN_RUN} or more top-level branches that does not reach the
      #     marker becomes one shared rule <rule>_run<k>, so the
      #     Constants.symbols_constants branches inside symbol_class_commands
      #     are written once, not once per marker;
      #   - a rule-level alternative of more than #{CHUNK} branches becomes a tree
      #     of rules <rule>_part<k> of at most #{CHUNK} branches each, which keeps
      #     the number of order-lint warnings linear.
      #
      # Constructs without a direct PARG form (each one a fixed table in the
      # generator; anything outside the tables stops generation):
      #   match(re)     the class of characters the native engine's regex
      #                 matches, as %x ranges (see the helper rules at the end).
      #                 match(/\\s/) is Unicode White_Space there, wider than
      #                 Ruby's /\\s/; preprocessing leaves only ASCII outside
      #                 \\mbox and \\text groups, where the two agree.
      #   .as("\\\\\\\\")   capture names must be identifiers: written `as row_break`.
      #                 Plurimath::Latex::Parse#parse renames the :"\\\\\\\\" key
      #                 to the String "\\\\\\\\"; Latexmath renames :row_break to
      #                 that String, which gives the same tree.
      #   decimal_marker
      #                 str(Utility.string_to_html_entity(configuration.decimal))
      #                 is fixed per parser instance, so the grammar is
      #                 specialised per marker: every rule that reaches the
      #                 marker is emitted once per marker with a __<entry>
      #                 suffix. Entries:
      #{marker_docs.join("\n")}
      #                 Specialised rules:
      #{spec.join("\n")}
      #                 Known divergence: Plurimath builds the symbol table once
      #                 per process (@@expression). If a process parses with one
      #                 marker and later with another, commands from that table
      #                 keep the first marker inside their arguments. This
      #                 grammar implements the fresh-process behaviour: one
      #                 marker throughout.
      #
      # Bindings: each entry starts at #{TREE_CAPTURE}__<entry>, which captures the
      # legacy root as #{TREE_CAPTURE}, and declares one structural binding,
      # `#{TREE_CAPTURE} -> #{TREE_CAPTURE} (raw)`, that carries the whole raw tree
      # unchanged. The bindings name no model fields; those belong to the
      # typed language model.
    TEXT
  end
end

options = { oracle: nil, export: false, check: false }
OptionParser.new do |o|
  o.banner = "usage: ruby scripts/generate_grammar.rb [--export --oracle DIR] [--check]"
  o.on("--export", "export data/latex-atoms.json again from the pinned Plurimath checkout") { options[:export] = true }
  o.on("--oracle DIR", "pinned Plurimath checkout (with --export)") { |v| options[:oracle] = File.expand_path(v) }
  o.on("--check", "compare instead of writing") { options[:check] = true }
end.parse!(ARGV)
abort "unexpected arguments #{ARGV.inspect}" unless ARGV.empty?
abort "--export needs --oracle DIR" if options[:export] && options[:oracle].nil?
abort "--oracle only applies with --export" if options[:oracle] && !options[:export]

stale = []
if options[:export]
  data = Export.dump(Export.run(options[:oracle]))
  if options[:check]
    stale << DATA unless File.exist?(DATA) && File.binread(DATA) == data
  else
    File.write(DATA, data)
    puts "wrote #{DATA} (#{data.bytesize} bytes)"
  end
else
  data = File.binread(DATA)
end

grammar = Generator.new(data).generate
if options[:check]
  stale << OUT unless File.exist?(OUT) && File.binread(OUT) == grammar
  abort "stale: #{stale.join(', ')}" unless stale.empty?
  puts "up to date"
else
  File.write(OUT, grammar)
  puts "wrote #{OUT} (#{grammar.bytesize} bytes)"
end
