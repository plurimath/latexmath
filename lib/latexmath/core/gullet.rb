module Latexmath
  module Core
    class Gullet
      def initialize(options)
      end

      def open_mouth(mouth, noautoclose)
        return unless mouth

        @mouth = mouth
        @pushback = []
        @autoclose = !noautoclose
      end

      # Do something, while reading stuff from a specific Mouth.
      # This reads ONLY from that mouth (or any mouth openned by code in that source),
      # and the mouth should end up empty afterwards, and only be closed here.
      def reading_from_mouth(mouth, closure)
        open_mouth(mouth, 1)
      end
    end
  end
end
