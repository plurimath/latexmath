# frozen_string_literal: true

require_relative "lib/latexmath/version"

Gem::Specification.new do |spec|
  spec.name = "latexmath"
  spec.version = Latexmath::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "LaTeX math parser by Plurimath."
  spec.description = <<~DESCRIPTION
    LaTeX math parser that runs a compiled Parsanol grammar artifact and
    returns a typed LaTeX model declared with LutaML Model. Used by
    Plurimath.
  DESCRIPTION

  spec.homepage = "https://github.com/plurimath/latexmath"
  spec.license = "BSD-2-Clause"

  spec.required_ruby_version = Gem::Requirement.new(">= 3.2.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/plurimath/latexmath"
  spec.metadata["changelog_uri"] = "https://github.com/plurimath/latexmath/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Only what the gem reads at run time, plus its documentation.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*.rb", "artifacts/**/*", "data/latex-symbols.json",
        "grammars/latex.wrappers.json", "model/**/*", "docs/**/*",
        "README.adoc", "CHANGELOG.md", "LICENSE.md"]
      .select { |f| File.file?(f) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "htmlentities", "~> 4.3"
  spec.add_dependency "lutaml-model", "~> 0.8", ">= 0.8.162"
  spec.add_dependency "parsanol", "~> 1.3", ">= 1.3.131"
end
