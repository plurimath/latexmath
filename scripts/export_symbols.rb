# frozen_string_literal: true

# The legacy LaTeX symbol table -> data/latex-symbols.json
#
# Usage:
#   BUNDLE_GEMFILE=<oracle>/.latexmath-oracle/Gemfile \
#     bundle exec ruby scripts/export_symbols.rb --oracle <oracle> [--check]
#
# <oracle> is the pinned Plurimath checkout (scripts/oracle/pins.yml) with
# its locked bundle (scripts/oracle/setup.rb). With --check the export is
# compared with the committed file instead of written; it exits 1 when they
# differ.
#
# The legacy transform turns the text of a captured symbol (a :symbols or
# :unicode_symbols capture, stripped) into a Plurimath symbol with
#
#   Plurimath::Utility.all_symbols_classes(:latex)[text]&.new ||
#     Plurimath::Math::Symbols::Symbol.new(text)
#
# This export writes that lookup table out, one record per spelling, so the
# gem can resolve symbols without loading Plurimath:
#
#   spelling  the captured text, as the table keys it: a command name
#             without its backslash ("alpha"), a hexadecimal entity
#             ("&#x3b1;"), or another spelling Plurimath lists for LaTeX
#   value     the Unicode text of the MathML the legacy class writes
#   mathml    that MathML element ("mi" or "mo")
#   kind      "symbol", or for a Plurimath paren "open", "close" or "paren"
#   class     the Plurimath class, relative to Plurimath::Math::Symbols
#
# A spelling the table lacks stays a plain symbol of its own text; that rule
# is the gem's, not data. Records are sorted by spelling (byte order), so the
# file is a pure function of the oracle.

require "digest"
require "json"
require "open3"
require "optparse"

ROOT = File.expand_path("..", __dir__)
DATA = File.join(ROOT, "data/latex-symbols.json")
FORMAT = "latexmath-symbols/v1"

def git(dir, *args)
  out, status = Open3.capture2("git", "-C", dir, *args)
  abort "git #{args.join(' ')} failed in #{dir}" unless status.success?
  out.strip
end

def kind(klass, object)
  return "symbol" unless klass <= Plurimath::Math::Symbols::Paren
  return "open" if object.open?
  return "close" if object.close?

  "paren"
end

# [element name, Unicode text] of the MathML +object+ writes; every legacy
# symbol and paren class writes one element holding one text node.
def mathml(object)
  node = object.to_mathml_without_math_tag(nil)
  text = node.nodes
  unless text.size == 1 && text.first.is_a?(String)
    abort "#{object.class} writes MathML that is not one element with one text node"
  end

  [node.name, Plurimath::Utility.html_entity_to_unicode(text.first)]
end

def export(oracle)
  require_relative "oracle/lib/latexmath_oracle/oracle_env"
  env = LatexmathOracle::OracleEnv.new(oracle)
  env.verify!
  $LOAD_PATH.unshift(File.join(env.checkout, "lib"))
  require "plurimath"

  table = Plurimath::Utility.all_symbols_classes(:latex)
  prefix = "Plurimath::Math::Symbols::"
  records = table.map do |spelling, klass|
    object = klass.new
    element, value = mathml(object)
    abort "#{klass} is outside #{prefix}" unless klass.name.start_with?(prefix)

    {
      "spelling" => spelling,
      "value" => value,
      "mathml" => element,
      "kind" => kind(klass, object),
      "class" => klass.name.delete_prefix(prefix),
    }
  end
  records.sort_by! { |r| r["spelling"].b }

  {
    "format" => FORMAT,
    "oracle" => {
      "repository" => env.pins.dig("plurimath", "repository"),
      "commit" => env.commit,
      "lib_tree" => git(env.checkout, "rev-parse", "#{env.commit}:lib"),
      "oracle_lock_sha256" => env.identity.fetch("lock_sha256"),
      "source" => "Plurimath::Utility.all_symbols_classes(:latex)",
    },
    "counts" => {
      "spellings" => records.size,
      "classes" => records.map { |r| r["class"] }.uniq.size,
      "kinds" => records.map { |r| r["kind"] }.tally.sort.to_h,
    },
    "symbols" => records,
  }
end

# One record per line keeps diffs of the 3,000-odd records readable.
def dump(data)
  head = data.except("symbols")
  lines = data.fetch("symbols").map { |r| "    #{JSON.generate(r)}" }
  body = JSON.pretty_generate(head).delete_suffix("\n}")
  "#{body},\n  \"symbols\": [\n#{lines.join(",\n")}\n  ]\n}\n"
end

options = { oracle: nil, check: false }
OptionParser.new do |o|
  o.banner = "usage: ruby scripts/export_symbols.rb --oracle DIR [--check]"
  o.on("--oracle DIR", "pinned Plurimath checkout") { |v| options[:oracle] = File.expand_path(v) }
  o.on("--check", "compare with data/latex-symbols.json instead of writing") { options[:check] = true }
end.parse!(ARGV)
abort "unexpected arguments #{ARGV.inspect}" unless ARGV.empty?
abort "--oracle DIR is required" unless options[:oracle]

data = dump(export(options[:oracle]))
if options[:check]
  abort "stale: #{DATA}" unless File.exist?(DATA) && File.binread(DATA) == data.b
  puts "up to date"
else
  File.write(DATA, data)
  puts "wrote #{DATA} (#{data.bytesize} bytes)"
end
