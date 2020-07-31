module Latexmath
  class Equation

    def initialize(string)
      @latex = string
    end

    def to_mathml
      <<~'INPUT'
        <?xml version="1.0" encoding="UTF-8"?>
        <math xmlns="http://www.w3.org/1998/Math/MathML" alttext="\varepsilon=\frac{1}{2}(J+J^{t})" display="block">
          <mrow>
            <mi>ε</mi>
            <mo>=</mo>
            <mrow>
              <mfrac>
                <mn>1</mn>
                <mn>2</mn>
              </mfrac>
              <mo>⁢</mo>
              <mrow>
                <mo stretchy="false">(</mo>
                <mrow>
                  <mi>J</mi>
                  <mo>+</mo>
                  <msup>
                    <mi>J</mi>
                    <mi>t</mi>
                  </msup>
                </mrow>
                <mo stretchy="false">)</mo>
              </mrow>
            </mrow>
          </mrow>
        </math>
      INPUT
    end

  end
end
