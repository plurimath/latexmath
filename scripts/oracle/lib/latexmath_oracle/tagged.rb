# frozen_string_literal: true

require "set"

module LatexmathOracle
  # Canonical tagged form for captured Ruby values.
  #
  # The form keeps every distinction the parity contract needs: hash versus
  # array, symbol versus string keys, key insertion order, nil versus a
  # missing key, empty string versus empty list, the class of every object,
  # and the text plus character and byte offsets of every parser slice.
  # Numbers are kept as their string spelling; nothing is sorted or
  # normalised. Strings that are not valid UTF-8 are kept as hex bytes.
  module Tagged
    module_function

    # +source+ is the text the slices point into (the preprocessed parser
    # input). When given, every slice also records its byte offset.
    def dump(value, source: nil)
      walk(value, source, Set.new.compare_by_identity)
    end

    def walk(value, source, path)
      case value
      when nil then { "t" => "nil" }
      when true, false then { "t" => "bool", "v" => value }
      when Integer then { "t" => "int", "v" => value.to_s }
      when Float then { "t" => "float", "v" => value.to_s }
      when Symbol then { "t" => "sym", "v" => value.to_s }
      when String then string(value)
      when Hash then container(value, path) { hash(value, source, path) }
      when Array then container(value, path) { array(value, source, path) }
      else
        return slice(value, source) if slice?(value)

        container(value, path) { object(value, source, path) }
      end
    end

    def string(value)
      if value.encoding == Encoding::UTF_8 && value.valid_encoding?
        { "t" => "str", "v" => value }
      elsif value.dup.force_encoding(Encoding::UTF_8).valid_encoding?
        { "t" => "str", "v" => value.dup.force_encoding(Encoding::UTF_8),
          "enc" => value.encoding.name }
      else
        { "t" => "bytes", "hex" => value.unpack1("H*"),
          "enc" => value.encoding.name }
      end
    end

    def hash(value, source, path)
      entries = value.map do |key, item|
        [walk(key, source, path), walk(item, source, path)]
      end
      { "t" => "hash", "entries" => entries }
    end

    def array(value, source, path)
      { "t" => "array", "items" => value.map { |item| walk(item, source, path) } }
    end

    def object(value, source, path)
      ivars = value.instance_variables.map do |name|
        [name.to_s, walk(value.instance_variable_get(name), source, path)]
      end
      node = { "t" => "object", "class" => value.class.name }
      if ivars.empty?
        node["v"] = string(value.to_s)
      else
        node["ivars"] = ivars
      end
      node
    end

    # A value already on the current path is a cycle; record it instead of
    # recursing forever. Shared, non-cyclic children are dumped each time.
    def container(value, path)
      return { "t" => "cycle", "class" => value.class.name } if path.include?(value)

      path.add(value)
      begin
        yield
      ensure
        path.delete(value)
      end
    end

    def slice?(value)
      name = value.class.name.to_s
      name.end_with?("::Slice") && value.respond_to?(:offset)
    end

    def slice(value, source)
      text = value.to_s
      node = string(text).merge("t" => "slice", "char_offset" => value.offset)
      if source && value.offset
        node["byte_offset"] = source[0, value.offset].bytesize
      end
      node
    end
  end
end
