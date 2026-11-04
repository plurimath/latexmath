# frozen_string_literal: true

module Latexmath
  # Fixed settings: the artifact entries, the engine names and where the
  # bundled artifacts live.
  module Configuration
    # Decimal marker => artifact entry name.
    DECIMAL_ENTRIES = {
      "." => "dot",
      "," => "comma",
      "٫" => "arabic", # ARABIC DECIMAL SEPARATOR
    }.freeze

    ENGINES = %i[auto native ruby].freeze

    ARTIFACT_DIR = File.expand_path("../../../artifacts", __dir__)
    DEFAULT_ARTIFACT_PATH = File.join(ARTIFACT_DIR, "latex.json")
    DEFAULT_BINDINGS_PATH = File.join(ARTIFACT_DIR, "latex.bindings.ruby.json")

    # The capture under which the declared bindings carry the legacy tree.
    TREE_CAPTURE = :latex_tree
    # The binding target the typed model is built from.
    MODEL_CAPTURE = :model

    # Capture names the PARG grammar spells differently from the legacy
    # grammar, and the key the legacy raw tree has instead. The legacy
    # grammar captures a matrix row break as :"\\\\" and then renames that
    # key to the String "\\\\"; PARG names must be identifiers.
    CAPTURE_RENAMES = { row_break: "\\\\" }.freeze

    # Deepest bracket nesting sent to the native engine off the main thread,
    # where the machine stack is small.
    THREAD_NATIVE_DEPTH = 25
  end
end
