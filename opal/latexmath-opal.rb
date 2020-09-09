require 'opal'
require 'corelib/string/unpack'
require 'pseudoenumerator'
require 'htmlentities'
require 'htmlentities/mappings/html4' # Dynamic require
require 'htmlentities/mappings/xhtml1' # Dynamic require
require 'htmlentities/mappings/expanded' # Dynamic require
require 'latexmath'

# Override 2 methods that use dynamic execution so we don't need to require a parser
class HTMLEntities
  class Encoder
    def build_basic_entity_encoder(instructions)
      if instructions.include?(:basic) || instructions.include?(:named)
        method = :encode_named
      elsif instructions.include?(:decimal)
        method = :encode_decimal
      elsif instructions.include?(:hexadecimal)
        method = :encode_hexadecimal
      end
      self.class.define_method :encode_basic do |char|
        send(method, char)
      end
    end

    def build_extended_entity_encoder(instructions)
      operations = [:named, :decimal, :hexadecimal] & instructions

      self.class.define_method :encode_extended do |char|

        operations.each do |encoder|
          encoded = send(:"encode_#{encoder}", char)
          return encoded if encoded
        end

        char
      end
    end
  end
end
