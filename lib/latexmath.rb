require "latexmath/version"
require "latexmath/latexml_requirement"
require "latexmath/equation"
require "htmlentities"
require "unicode2latex"

module Latexmath
  class Error < StandardError; end
  # Your code goes here...

  Requirements = {
    latexml: LatexmlRequirement.new
  }

  def self.parse(string)
    lxm_input = Unicode2LaTeX.unicode2latex(HTMLEntities.new.decode(string))

    # parse
    Equation.new(lxm_input)
  end

end
