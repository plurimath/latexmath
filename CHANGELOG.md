# Changelog

## 1.1.0 (unreleased)

### Added

- `Latexmath::Model::MathSymbol` carries `value` and `kind` as model
  attributes, so they appear in the LML export (`model/latex.lml.json`)
  as well as on the object. Before, they were only methods and the export
  had only `spelling`. (#58)
- `docs/latex.adoc` describes the LaTeX math the grammar accepts and which
  model class each construct becomes. The README links to it. (#62)

### Changed

- Parsanol 1.3.134 or later is required (still within `~> 1.3`). (#59)
- The pinned testsuite replay in CI runs on Windows and macOS as well as
  Linux. (#60)

### Fixed

- With `engine: :auto`, input that hits the native engine's recursion limit
  under Parsanol 1.3.134 is parsed again on the Ruby engine instead of
  being reported as a parse error. With `engine: :native` it raises
  `Latexmath::NestingTooDeep`. (#59)

## 1.0.0

Latexmath is now a LaTeX math parser that returns a typed model, built for
Plurimath. It replaces the 0.1.x LaTeX-to-MathML converter, and is not
backward compatible with it.

### Breaking changes

- `Latexmath.parse(input, decimal: ".", engine: :auto)` returns a
  `Latexmath::Model::Document`, a typed model of the formula built with
  LutaML Model. In 0.1.x it returned an equation object whose `to_mathml`
  wrote MathML.
- The 0.1.x converter is removed: `Latexmath.legacy_parse`, the
  `Latexmath::Tokenizer`, `Aggregator`, `Converter`, `Equation`, `Symbol`
  and `XML` classes, `Latexmath::Constants::SYMBOLS`, the `latexmath`
  executable and the Opal build (`dist/latexmath.js`).
- Invalid input raises `Latexmath::ParseError` with the position in the
  caller's input (`char_offset`, `byte_offset`). Every error Latexmath
  raises on purpose is a `Latexmath::Error`.
- Ruby 3.2 or later is required. The runtime dependencies are Parsanol,
  LutaML Model and HTMLEntities; Ox is no longer used. LaTeXML is no longer
  needed, even for development.

### Moving from 0.1.x

Latexmath no longer writes MathML. To convert LaTeX math to MathML or
another format, use Plurimath:

```ruby
require "plurimath"

Plurimath::Math.parse("x^2", :latex).to_mathml
```

Code that only needs the structure of a formula can read the model from
`Latexmath.parse` directly; see `docs/model-contract.adoc`. To keep the
0.1.x converter, pin `gem "latexmath", "~> 0.1.5"`.

### Other changes

- The grammar is Plurimath's LaTeX grammar, compiled with Parsanol into a
  checksummed artifact (`artifacts/latex.json`). It runs on Parsanol's
  native engine where available and on its Ruby engine elsewhere, with the
  same results.
- CI replays the LaTeX generation of plurimath-testsuite pinned in
  `spec/fixtures/testsuite-pin.yml` and compares the parse tree with the
  pinned Plurimath release for every LaTeX case of the testsuite.
- The gem is released by trusted publishing from the `release` workflow.
