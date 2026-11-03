# frozen_string_literal: true

# grammars/latex.parg -> artifacts/latex.json (Parsanol PARG artifact)
#                     + artifacts/latex.bindings.<target>.json
#
# Usage:
#   bundle exec ruby scripts/compile.rb [--determinism]
#
# The bundle must provide the `parsanol` executable, 1.3.131 or later
# (earlier releases accept --bindings but emit nothing); the version is
# recorded in the checksum manifest. Steps, as in amath:
#   1. scripts/generate_grammar.rb --check (the .parg matches data/latex-atoms.json)
#   2. bundle exec parsanol parg compile --bindings all
#        -> artifacts/latex.json and one declared bindings artifact per
#           Parsanol binding target, beside it
#   3. bundle exec parsanol parg check    (artifact matches source + compiler)
#   4. verify every bindings artifact: kind, checksum, target, binding
#      version, entries, the entries' declared bindings, and pairing with
#      the parse artifact
#   5. --determinism: compile again into a temporary directory and require
#      identical bytes for the parse artifact and every bindings artifact
#   6. write artifacts/latex.checksums.txt
# Exits nonzero on the first failing step.

require "digest"
require "json"
require "open3"
require "parsanol"
require "rbconfig"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
GRAMMAR = File.join(ROOT, "grammars/latex.parg")
EXPORT = File.join(ROOT, "data/latex-atoms.json")
ARTIFACT = File.join(ROOT, "artifacts/latex.json")
CHECKSUMS = File.join(ROOT, "artifacts/latex.checksums.txt")

determinism = ARGV.delete("--determinism")
abort "usage: ruby scripts/compile.rb [--determinism]" unless ARGV.empty?

def run!(*cmd)
  out, status = Open3.capture2e(*cmd, chdir: ROOT)
  puts out
  abort "FAILED (exit #{status.exitstatus}): #{cmd.join(' ')}" unless status.success?
  out
end

def relative(path)
  path.delete_prefix("#{ROOT}/")
end

# Parsanol::PARG::Bindings::Artifact::TARGETS, in its order.
BINDING_TARGETS = Parsanol::PARG::Bindings::Artifact::TARGETS

# The bindings artifact the compiler writes beside +artifact+ for +target+.
def binding_path(artifact, target)
  artifact.sub(/\.json\z/, ".bindings.#{target}.json")
end

def binding_files(artifact)
  BINDING_TARGETS.map { |target| binding_path(artifact, target) }
end

def compile!(output)
  run!("bundle", "exec", "parsanol", "parg", "compile", GRAMMAR, "-o", output, "--bindings", "all")
  missing = BINDING_TARGETS.reject { |target| File.file?(binding_path(output, target)) }
  abort "FAILED: no bindings artifact emitted for #{missing.join(', ')}" unless missing.empty?
end

# Every bindings artifact loads with Parsanol's own verifier (kind,
# checksum, target, binding version), pairs with the parse artifact and
# declares exactly the parse artifact's entries and their bindings.
def verify_bindings!(artifact)
  parse = Parsanol::PARG::Artifact.load(artifact)
  expected = parse.entries.to_h { |name| [name, parse.entry(name)["bindings"]] }
  BINDING_TARGETS.each do |target|
    path = binding_path(artifact, target)
    bindings = Parsanol::PARG::Bindings::Artifact.from_json(File.read(path, encoding: "UTF-8"), target: target)
    bindings.pair_with!(parse)
    abort "FAILED: #{relative(path)} entries #{bindings.entry_names.inspect} != #{expected.keys.inspect}" unless bindings.entry_names == expected.keys

    expected.each do |name, records|
      abort "FAILED: #{relative(path)} entry #{name} has no bindings" if Array(records).empty?
      abort "FAILED: #{relative(path)} entry #{name} bindings differ from the parse artifact" unless bindings.bindings(name) == records
    end
    puts "bindings: #{relative(path)} target=#{bindings.target} version=#{bindings.binding_version} paired"
  end
end

run!(RbConfig.ruby, "scripts/generate_grammar.rb", "--check")
# Bindings files from before the --bindings flag (latex.<target>.bindings.json).
Dir[File.join(ROOT, "artifacts/latex.*.bindings.json")].each { |f| File.delete(f) }
compile!(ARTIFACT)
run!("bundle", "exec", "parsanol", "parg", "check", "--source", GRAMMAR, "--artifact", ARTIFACT)
verify_bindings!(ARTIFACT)
emitted = [ARTIFACT, *binding_files(ARTIFACT)]

if determinism
  Dir.mktmpdir do |dir|
    again = File.join(dir, File.basename(ARTIFACT))
    compile!(again)
    others = [again, *binding_files(again)]
    names = ->(list) { list.map { |f| File.basename(f) } }
    abort "FAILED: recompilation emitted #{names.call(others)}, not #{names.call(emitted)}" unless names.call(others) == names.call(emitted)

    emitted.zip(others).each do |mine, other|
      abort "FAILED: #{relative(mine)} is not byte-identical on recompilation" unless File.binread(mine) == File.binread(other)
    end
    puts "determinism: #{emitted.size} recompiled file(s) byte-identical"
  end
end

envelope = JSON.parse(File.binread(ARTIFACT))
lines = [
  "# Written by scripts/compile.rb. Envelope checksums are Parsanol's own;",
  "# the sha256 lines are of the files' bytes.",
  "artifact_checksum #{envelope.fetch('checksum')}",
  "compiler_version #{envelope.fetch('compiler_version')}",
  "edition #{envelope.fetch('edition', 2)}",
  "source_hash sha256:#{envelope.fetch('source_hash')}",
  "#{relative(ARTIFACT)} sha256:#{Digest::SHA256.file(ARTIFACT).hexdigest}",
]
binding_files(ARTIFACT).each do |file|
  payload = JSON.parse(File.binread(file))
  lines << "bindings #{payload.fetch('target')} checksum #{payload.fetch('checksum')}"
  lines << "#{relative(file)} sha256:#{Digest::SHA256.file(file).hexdigest}"
end
lines.push(
  "#{relative(GRAMMAR)} sha256:#{Digest::SHA256.file(GRAMMAR).hexdigest}",
  "#{relative(EXPORT)} sha256:#{Digest::SHA256.file(EXPORT).hexdigest}",
  "entries #{envelope.fetch('entries').keys.join(' ')}",
  "order_warnings #{envelope.dig('lint', 'order_warnings').size}",
)
File.write(CHECKSUMS, "#{lines.join("\n")}\n")
puts File.read(CHECKSUMS)
