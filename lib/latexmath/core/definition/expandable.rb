module Latexmath
  module Core
    module Definition
      class Expandable
        attr_reader :cs
        def initialize(cs, sparamlist, expansion, options)
          @cs = cs
        end
      end
    end
  end
end
