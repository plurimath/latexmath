# frozen_string_literal: true

# Child process for one oracle row. capture.rb starts it with BUNDLE_GEMFILE
# pointing at <oracle checkout>/.latexmath-oracle/Gemfile, writes one JSON
# request ({"row": {...}}) to stdin and reads one JSON document from stdout.
#
# It records four boundaries of the legacy Plurimath LaTeX path:
#   1. caller input and options
#   2. legacy preprocessing (Plurimath::Latex::Parser#text)
#   3. raw grammar tree (Plurimath::Latex::Parse#parse of the preprocessed text)
#   4. facade outcome (Plurimath::Math.parse) and every writer's output
#
# A facade parse error is a refusal and is reported as data with exit 0.
# Any other failure of this script exits non-zero and counts as a crash.

require "digest"
require "json"

# Keep the protocol channel private: anything the libraries print goes to
# stderr instead of mixing into the JSON reply.
PROTOCOL = $stdout.dup
$stdout.reopen($stderr)

require "bundler/setup"
require "plurimath"
require_relative "lib/latexmath_oracle/tagged"

WRITERS = %w[asciimath latex mathml omml html unicodemath].freeze

def error_info(error, source = nil)
  info = {
    "class" => error.class.name,
    "message_first_line" => error.message.to_s.lines.first.to_s.chomp[0, 160],
    "message_sha256" => Digest::SHA256.hexdigest(error.message.to_s),
  }
  cause = error.respond_to?(:parse_failure_cause) ? error.parse_failure_cause : nil
  if cause.respond_to?(:pos) && cause.pos.is_a?(Integer)
    info["char_offset"] = cause.pos
    info["byte_offset"] = source[0, cause.pos].bytesize if source
  end
  info
end

def with_locale(locale, &block)
  return yield if locale.nil?

  Plurimath.with_configuration do |config|
    config.locale = locale
    block.call
  end
end

def runtime
  {
    "ruby" => RUBY_DESCRIPTION,
    "plurimath" => Plurimath::VERSION,
    "parsanol" => Gem.loaded_specs["parsanol"]&.version&.to_s,
    "parsanol_platform" => Gem.loaded_specs["parsanol"]&.platform&.to_s,
    "parsanol_native" => defined?(Parsanol::Native) && Parsanol::Native.respond_to?(:available?) ? Parsanol::Native.available? : nil,
  }
end

request = JSON.parse($stdin.read)
row = request.fetch("row")
input = row.fetch("input")
configuration = row["configuration"] || {}
options = {}
options[:locale] = configuration["locale"].to_sym if configuration.key?("locale")

reply = {
  "id" => row.fetch("id"),
  "runtime" => runtime,
  "input" => LatexmathOracle::Tagged.dump(input),
  "options" => LatexmathOracle::Tagged.dump(options),
}

# Same option handling as Plurimath::Math.parse at the pinned commit.
normalized = Plurimath::Math.send(:normalize_parse_options, options)

with_locale(normalized[:locale]) do
  begin
    preprocessed = Plurimath::Latex::Parser.new(input).text
    reply["preprocessed"] = { "ok" => LatexmathOracle::Tagged.dump(preprocessed) }
  rescue StandardError => e
    reply["preprocessed"] = { "error" => error_info(e) }
  end

  if preprocessed
    begin
      tree = Plurimath::Latex::Parse.new.parse(preprocessed)
      reply["raw_tree"] = { "ok" => LatexmathOracle::Tagged.dump(tree, source: preprocessed) }
    rescue StandardError => e
      reply["raw_tree"] = { "error" => error_info(e, preprocessed) }
    end
  end
end

begin
  formula = Plurimath::Math.parse(input, :latex, **options)
rescue Plurimath::Error => e
  reply["status"] = "refused"
  reply["refusal"] = {
    "stage" => if !reply["preprocessed"].key?("ok") then "preprocess"
               elsif !reply["raw_tree"].key?("ok") then "grammar"
               else "transform"
               end,
    "error" => error_info(e),
  }
else
  reply["status"] = "ok"
  reply["formula"] = LatexmathOracle::Tagged.dump(formula)
  reply["writers"] = WRITERS.to_h do |writer|
    [writer, { "ok" => LatexmathOracle::Tagged.dump(formula.public_send("to_#{writer}")) }]
  rescue StandardError => e
    [writer, { "error" => error_info(e) }]
  end
end

PROTOCOL.write(JSON.generate(reply))
PROTOCOL.flush
