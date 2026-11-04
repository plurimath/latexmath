# frozen_string_literal: true

require "json"

module Latexmath
  # The legacy LaTeX symbol table, exported from the pinned Plurimath by
  # scripts/export_symbols.rb into data/latex-symbols.json: for every
  # spelling a symbol capture can have, its Unicode value, the MathML
  # element the legacy writer uses and its kind. Loading it needs no
  # Plurimath.
  #
  # The legacy transform looks a captured symbol up by its text, stripped;
  # text the table lacks stays a plain symbol of that text (#resolve).
  module Symbols
    DATA_PATH = File.expand_path("../../data/latex-symbols.json", __dir__)
    FORMAT = "latexmath-symbols/v1"

    # +spelling+: the captured text ("alpha", "&#x3b1;", "("); +value+: its
    # Unicode text; +mathml+: "mi" or "mo", nil for text the table lacks;
    # +kind+: "symbol", "open", "close" or "paren"; +plurimath_class+: the
    # legacy class relative to Plurimath::Math::Symbols.
    Entry = Struct.new(:spelling, :value, :mathml, :kind, :plurimath_class, keyword_init: true)

    @table = nil
    @lock = Mutex.new

    module_function

    # The Entry for the captured +text+, or nil when the table lacks it.
    def lookup(text)
      table[:entries][text.to_s.strip]
    end

    # The Entry for the captured +text+; text the table lacks becomes a
    # plain symbol of its own (stripped) text, as in the legacy transform.
    def resolve(text)
      key = text.to_s.strip
      table[:entries][key] ||
        Entry.new(spelling: key, value: key, mathml: nil, kind: "symbol", plurimath_class: "Symbol").freeze
    end

    def size
      table[:entries].size
    end

    # Where the table comes from: the oracle repository, commit, lib tree and
    # Ruby of the export.
    def provenance
      table[:oracle]
    end

    def table
      @lock.synchronize { @table ||= load_table(DATA_PATH) }
    end

    def load_table(path)
      data = JSON.parse(File.read(path, encoding: "UTF-8"))
      raise ArtifactError, "#{path} is #{data['format'].inspect}, not #{FORMAT}" unless data["format"] == FORMAT

      entries = data.fetch("symbols").to_h do |r|
        entry = Entry.new(spelling: r.fetch("spelling"), value: r.fetch("value"), mathml: r.fetch("mathml"),
                          kind: r.fetch("kind"), plurimath_class: r.fetch("class")).freeze
        [entry.spelling, entry]
      end
      raise ArtifactError, "#{path} repeats a spelling" unless entries.size == data["symbols"].size

      { oracle: data.fetch("oracle").freeze, entries: entries.freeze }.freeze
    rescue JSON::ParserError, KeyError, SystemCallError => e
      raise ArtifactError, "symbol table #{path} cannot be loaded: #{e.class}: #{e.message}"
    end

    private_class_method :table, :load_table
  end
end
