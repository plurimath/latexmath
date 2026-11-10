# frozen_string_literal: true

require "json"
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "lutaml/model"
require "lutaml/model/lml"
require "latexmath/model"

abort "portable LML bundle API is unavailable in this lutaml-model" unless Lutaml::Model::Lml.respond_to?(:export_bundle)
abort "usage: ruby scripts/export_portable_models.rb OUTPUT" unless ARGV.length == 1

# Make Ruby's implicit attribute mappings visible to foreign code generators
# only in this isolated export process.
Latexmath::Model.constants.each do |name|
  klass = Latexmath::Model.const_get(name)
  next unless klass.is_a?(Class) && klass < Lutaml::Model::Serializable

  names = klass.attributes.keys
  klass.json do
    names.each { |attribute| map attribute.to_s, to: attribute }
  end
end
bundle = Lutaml::Model::Lml.export_bundle(Latexmath::Model::Document)
File.write(ARGV.first, "#{JSON.pretty_generate(bundle.to_h)}\n")
puts "exported #{bundle.to_h.fetch('models').size} models to #{ARGV.first}"
