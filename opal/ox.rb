# A minimal Ox implementation for Opal

module Ox
  CODER = HTMLEntities.new

  class Document
    def initialize
      @root = nil
    end

    def << child
      @root = child
    end

    def dump
      @root.dump
    end
  end

  class Element
    def initialize tag_name
      @tag_name = tag_name
      @attrs = {}
      @children = []
    end

    def []= key, value
      @attrs[key] = value
    end

    def << child
      @children << child
      self
    end

    def value= value
      @tag_name = value
    end

    def dump
      attrs = @attrs.map do |k,v|
        %Q< #{k}="#{CODER.encode(v)}">
      end.join("")
      "<#{@tag_name}#{attrs}>"+
        @children.map(&:dump).join("")+
      "</#{@tag_name}>"
    end
  end

  class Raw
    def initialize value
      @value = value
    end

    def dump
      #CODER.encode(@value)
      @value
    end
  end

  def self.dump doc
    doc.dump
  end
end
