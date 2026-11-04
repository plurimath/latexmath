# frozen_string_literal: true

require "json"

module Latexmath
  # The inverse of the grammar's shape normalization (option F), for the
  # raw-tree boundary and parity replay only.
  #
  # The generator only ADDS captures, listed in grammars/latex.wrappers.json
  # as {name => kind}. Unwrap replaces each wrapper by the value legacy
  # produced there and re-runs Parslet's own flattening algebra
  # (Parsanol::Atoms::CanFlatten#merge_fold / #flatten_repetition) over the
  # parts, bottom-up:
  #
  #   hash   entries are split, in order, into runs of ordinary keys (one hash
  #          part each) and wrapper keys (one part each, by kind):
  #            text       -> the wrapped value (nil / [] -> "", legacy unnamed)
  #            empty      -> "" (String)
  #            list       -> the list ([] -> "")
  #            nil        -> nil
  #            text_list  -> the text; "" (or []) -> [] (legacy named, empty)
  #            items      -> the list, unchanged
  #          then folded with merge_fold, as legacy folded the sequence.
  #          A hash of nil-kind wrappers only is nil.
  #   array  elements are unwrapped, then flatten_repetition (named).
  module Unwrap
    extend Parsanol::Atoms::CanFlatten

    PATH = File.expand_path("../../../grammars/latex.wrappers.json", __dir__)

    @wrappers = nil
    @lock = Mutex.new

    module_function

    # The wrapper table of the bundled grammar.
    def wrappers
      @lock.synchronize { @wrappers ||= load(PATH).freeze }
    end

    def load(path)
      JSON.parse(File.read(path, encoding: "UTF-8")).fetch("wrappers")
    end

    def call(value, wrappers = self.wrappers)
      case value
      when Hash then unwrap_hash(value, wrappers)
      when Array then Unwrap.send(:flatten_repetition, value.map { |v| call(v, wrappers) }, true)
      else value
      end
    end

    def unwrap_hash(value, wrappers)
      return value.to_h { |k, v| [k, call(v, wrappers)] } if value.keys.none? { |k| wrappers.key?(k.to_s) }

      parts = []
      run = nil
      only_nil = true
      value.each do |k, v|
        kind = wrappers[k.to_s]
        if kind
          parts << run if run
          run = nil
          only_nil &&= kind == "nil"
          parts << part(kind, call(v, wrappers))
        else
          only_nil = false
          (run ||= {})[k] = call(v, wrappers)
        end
      end
      parts << run if run
      return nil if only_nil

      Unwrap.send(:foldl, parts) { |l, r| Unwrap.send(:merge_fold, l, r) }
    end

    def part(kind, v)
      case kind
      when "text" then v.nil? || v == [] ? +"" : v
      when "empty" then +""
      when "list" then v == [] ? +"" : v
      when "nil" then nil
      when "text_list" then v == [] || v == "" ? [] : v
      when "items" then v
      else raise ArgumentError, "unknown wrapper kind #{kind}"
      end
    end

    private_class_method :unwrap_hash, :part
  end
end
