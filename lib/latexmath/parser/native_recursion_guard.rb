# frozen_string_literal: true

module Latexmath
  # Raised inside Parsanol's native error path when the native engine hit
  # its recursion limit, before Parsanol's interpreter reparse runs (that
  # reparse can take minutes or exhaust the Ruby stack on deep input).
  class NativeRecursionLimit < Error; end
  private_constant :NativeRecursionLimit

  # Parsanol::Native.raise_native_parse_error translates a native failure.
  # While Latexmath's own native call runs on this thread, this hook turns a
  # recursion-limit failure into NativeRecursionLimit; every other failure,
  # and every other caller of Parsanol, is unaffected. (The same guard as
  # amath's.)
  module NativeRecursionGuard
    MESSAGE = /\A(?:Maximum recursion depth \(\d+\) exceeded|Recursion limit exceeded\b)/
    KEY = :latexmath_native_recursion_guard

    def self.watch
      outer = Thread.current[KEY]
      Thread.current[KEY] = true
      yield
    ensure
      Thread.current[KEY] = outer
    end

    def self.installed?
      Parsanol::Native.singleton_class.ancestors.include?(self)
    end

    def raise_native_parse_error(error, grammar, input)
      if Thread.current[KEY] && error.message.match?(MESSAGE)
        raise NativeRecursionLimit, error.message.lines.first.strip, cause: nil
      end

      super
    end
  end

  if Parsanol::Native.singleton_class.method_defined?(:raise_native_parse_error)
    Parsanol::Native.singleton_class.prepend(NativeRecursionGuard)
  end
end
