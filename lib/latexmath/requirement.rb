module Latexmath
  class Requirement
    def satisfied
      raise NotImplementedError("abstract method")
    end

    def cmd
      raise NotImplementedError("abstract method")
    end
  end
end

