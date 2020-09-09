CONVERTER_PARAMS = [
  ['single identifier', 'x', '<mi>x</mi>'],
  ['multiple identifier', 'xyz', '<mi>x</mi><mi>y</mi><mi>z</mi>'],
  ['single number', '3', '<mn>3</mn>'],
  ['multiple numbers', '333', '<mn>333</mn>'],
  ['decimal numbers', '12.34', '<mn>12.34</mn>'],
  ['numbers and identifiers', '12x', '<mn>12</mn><mi>x</mi>'],
  ['single operator', '+', '<mo>&#x0002B;</mo>'],
  ['single operator', '-', '<mo>&#x02212;</mo>'],
  [
    'numbers and operators',
    '3-2',
    '<mn>3</mn><mo>&#x02212;</mo><mn>2</mn>'
  ],
  [
    'numbers, identifiers and operators',
    '3x*2',
    '<mn>3</mn><mi>x</mi><mo>&#x0002A;</mo><mn>2</mn>'
  ],
  ['single group', '{a}', '<mrow><mi>a</mi></mrow>'],
  [
    'multiple groups',
    '{a}{b}',
    '<mrow><mi>a</mi></mrow><mrow><mi>b</mi></mrow>'
  ],
  [
    'inner group',
    '{a+{b}}',
    '<mrow><mi>a</mi><mo>&#x0002B;</mo><mrow><mi>b</mi></mrow></mrow>'
  ],
  [
    'over',
    '1 \\over 2',
    '<mfrac><mrow><mn>1</mn></mrow><mrow><mn>2</mn></mrow></mfrac>'
  ],
  [
    'over inside braces',
    '{1 \\over 2}',
    '<mrow><mfrac><mrow><mn>1</mn></mrow><mrow><mn>2</mn></mrow></mfrac></mrow>'
  ],
  [
    'complex matrix',
    '\\begin{matrix}a_{1} & b_{2} \\\\ c_{3} & d_{4} \\end{matrix}',
    '<mtable>
        <mtr>
          <mtd>
            <msub><mi>a</mi><mrow><mn>1</mn></mrow></msub>
          </mtd>
          <mtd>
            <msub><mi>b</mi><mrow><mn>2</mn></mrow></msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd>
            <msub><mi>c</mi><mrow><mn>3</mn></mrow></msub>
          </mtd>
          <mtd>
            <msub><mi>d</mi><mrow><mn>4</mn></mrow></msub>
          </mtd>
        </mtr>
      </mtable>'
  ],
  [
    'null delimiter',
    '\\left\\{ \\begin{array} { l } { 3x - 5y + 4z = 0} \\\\ { x - y + 8z = 0} \\\\ { 2x - 6y + z = 0} \\end{array} \\right.',
    '<mrow>
        <mo stretchy="true" fence="true" form="prefix">
          &#x0007B;
        </mo>
        <mrow>
          <mtable>
            <mtr>
              <mtd columnalign="left">
                <mn>
                  3
                </mn>
                <mi>
                  x
                </mi>
                <mo>
                  &#x02212;
                </mo>
                <mn>
                  5
                </mn>
                <mi>
                  y
                </mi>
                <mo>
                  &#x0002B;
                </mo>
                <mn>
                  4
                </mn>
                <mi>
                  z
                </mi>
                <mo>
                  &#x0003D;
                </mo>
                <mn>
                  0
                </mn>
              </mtd>
            </mtr>
            <mtr>
              <mtd columnalign="left">
                <mi>
                  x
                </mi>
                <mo>
                  &#x02212;
                </mo>
                <mi>
                  y
                </mi>
                <mo>
                  &#x0002B;
                </mo>
                <mn>
                  8
                </mn>
                <mi>
                  z
                </mi>
                <mo>
                  &#x0003D;
                </mo>
                <mn>
                  0
                </mn>
              </mtd>
            </mtr>
            <mtr>
              <mtd columnalign="left">
                <mn>
                  2
                </mn>
                <mi>
                  x
                </mi>
                <mo>
                  &#x02212;
                </mo>
                <mn>
                  6
                </mn>
                <mi>
                  y
                </mi>
                <mo>
                  &#x0002B;
                </mo>
                <mi>
                  z
                </mi>
                <mo>
                  &#x0003D;
                </mo>
                <mn>
                  0
                </mn>
              </mtd>
            </mtr>
          </mtable>
        </mrow>
        <mo stretchy="true" fence="true" form="postfix"/>
      </mrow>'
  ],
  ['subscript', 'a_b', '<msub><mi>a</mi><mi>b</mi></msub>'],
  ['superscript', 'a^b', '<msup><mi>a</mi><mi>b</mi></msub>'],
  [
    'subscript and superscript',
    'a_b^c',
    '<msubsup><mi>a</mi><mi>b</mi><mi>c</mi></msubsup>'
  ],
  [
    'superscript and subscript',
    'a^b_c',
    '<msubsup><mi>a</mi><mi>c</mi><mi>b</mi></msubsup>'
  ],
  [
    'subscript within curly braces',
    '{a_b}',
    '<mrow><msub><mi>a</mi><mi>b</mi></msub></mrow>'
  ],
  [
    'superscript within curly braces',
    '{a^b}',
    '<mrow><msup><mi>a</mi><mi>b</mi></msup></mrow>'
  ],
  [
    'superscript, subscript and curly braces',
    'a^{i+1}_3',
    '<msubsup>
        <mi>a</mi>
        <mn>3</mn>
        <mrow><mi>i</mi><mo>&#x0002B;</mo><mn>1</mn></mrow>
      </msubsup>'
  ],
  [
    'simple fraction',
    '\\frac{1}{2}',
    '<mfrac><mrow><mn>1</mn></mrow><mrow><mn>2</mn></mrow></mfrac>'
  ],
  ['square root', '\\sqrt{2}', '<msqrt><mrow><mn>2</mn></mrow></msqrt>'],
  [
    'root',
    '\\sqrt[3]{2}',
    '<mroot><mrow><mn>2</mn></mrow><mrow><mn>3</mn></mrow></mroot>'
  ],
  [
    'binomial',
    '\\binom{2}{3}',
    '<mo>&#x00028;</mo>
      <mfrac linethickness="0">
        <mrow><mn>2</mn></mrow>
        <mrow><mn>3</mn></mrow>
      </mfrac>
      <mo>&#x00029;</mo>'
  ],
  [
    'left and right',
    '\\left(x\\right)',
    '<mrow><mo stretchy="true" fence="true" form="prefix">&#x00028;</mo><mrow><mi>x</mi></mrow><mo stretchy="true" fence="true" form="postfix">&#x00029;</mo></mrow>'
  ],
  ['space', '\\,', '<mspace width="0.167em" />'],
  [
    'overline',
    '\\overline{a}',
    '<mover><mrow><mi>a</mi></mrow><mo stretchy="true">&#x000AF;</mo></mover>'
  ],
  [
    'underline',
    '\\underline{a}',
    '<munder>
        <mrow>
          <mi>a</mi>
        </mrow>
        <mo stretchy="true">
          &#x00332;
        </mo>
      </munder>'
  ],
  [
    'matrix',
    '\\begin{matrix}a & b \\\\ c & d \\end{matrix}',
    '<mtable>
        <mtr>
          <mtd>
            <mi>a</mi>
          </mtd>
          <mtd>
            <mi>b</mi>
          </mtd>
        </mtr>
        <mtr>
          <mtd>
            <mi>c</mi>
          </mtd>
          <mtd>
            <mi>d</mi>
          </mtd>
        </mtr>
      </mtable>'
  ],
  [
    'matrix without begin and end',
    '\\matrix{a & b \\\\ c & d}',
    '<mtable>
        <mtr>
          <mtd>
            <mi>a</mi>
          </mtd>
          <mtd>
            <mi>b</mi>
          </mtd>
        </mtr>
        <mtr>
          <mtd>
            <mi>c</mi>
          </mtd>
          <mtd>
            <mi>d</mi>
          </mtd>
        </mtr>
      </mtable>'
  ],
  [
    'matrix with alignment',
    '\\begin{matrix*}[r]a & b \\\\ c & d \\end{matrix*}',
    '<mtable>
        <mtr>
          <mtd columnalign="right"><mi>a</mi></mtd>
          <mtd columnalign="right"><mi>b</mi></mtd>
        </mtr>
        <mtr>
          <mtd columnalign="right"><mi>c</mi></mtd>
          <mtd columnalign="right"><mi>d</mi></mtd>
        </mtr>
      </mtable>'
  ],
  [
    'matrix with negative sign',
    '\\begin{matrix}-a & b \\\\ c & d \\end{matrix}',
    '<mtable>
      <mtr>
        <mtd>
          <mo>
            &#x02212;
          </mo>
          <mi>
            a
          </mi>
        </mtd>
        <mtd>
          <mi>
            b
          </mi>
        </mtd>
      </mtr>
      <mtr>
        <mtd>
          <mi>
            c
          </mi>
        </mtd>
        <mtd>
          <mi>
            d
          </mi>
        </mtd>
      </mtr>
    </mtable>'
  ],
  [
    'pmatrix',
    '\\begin{pmatrix}a & b \\\\ c & d \\end{pmatrix}',
    '<mo>
      &#x00028;
    </mo>
    <mtable>
      <mtr>
        <mtd>
          <mi>
            a
          </mi>
        </mtd>
        <mtd>
          <mi>
            b
          </mi>
        </mtd>
      </mtr>
      <mtr>
        <mtd>
          <mi>
            c
          </mi>
        </mtd>
        <mtd>
          <mi>
            d
          </mi>
        </mtd>
      </mtr>
    </mtable>
    <mo>
      &#x00029;
    </mo>'
  ],
  [
    'simple array',
    '\\begin{array}{cr} 1 & 2 \\\\ 3 & 4 \\end{array}',
    '<mtable>
      <mtr>
        <mtd columnalign="center">
          <mn>
            1
          </mn>
        </mtd>
        <mtd columnalign="right">
          <mn>
            2
          </mn>
        </mtd>
      </mtr>
      <mtr>
        <mtd columnalign="center">
          <mn>
            3
          </mn>
        </mtd>
        <mtd columnalign="right">
          <mn>
            4
          </mn>
        </mtd>
      </mtr>
    </mtable>'
  ],
  [
    'array with vertical bar',
    '\\begin{array}{c|rl} 1 & 2 & 3 \\\\ 4 & 5 & 6 \\end{array}',
    '<mtable columnlines="solid none">
      <mtr>
        <mtd columnalign="center">
          <mn>
            1
          </mn>
        </mtd>
        <mtd columnalign="right">
          <mn>
            2
          </mn>
        </mtd>
        <mtd columnalign="left">
          <mn>
            3
          </mn>
        </mtd>
      </mtr>
      <mtr>
        <mtd columnalign="center">
          <mn>
            4
          </mn>
        </mtd>
        <mtd columnalign="right">
          <mn>
            5
          </mn>
        </mtd>
        <mtd columnalign="left">
          <mn>
            6
          </mn>
        </mtd>
      </mtr>
    </mtable>'
  ],
  [
    'array with horizontal lines',
    '\\begin{array}{cr} 1 & 2 \\\\ 3 & 4 \\\\ \\hline 5 & 6 \\end{array}',
    '<mtable rowlines="none solid">
      <mtr>
        <mtd columnalign="center">
          <mn>
            1
          </mn>
        </mtd>
        <mtd columnalign="right">
          <mn>
            2
          </mn>
        </mtd>
      </mtr>
      <mtr>
        <mtd columnalign="center">
          <mn>
            3
          </mn>
        </mtd>
        <mtd columnalign="right">
          <mn>
            4
          </mn>
        </mtd>
      </mtr>
      <mtr>
        <mtd columnalign="center">
          <mn>
            5
          </mn>
        </mtd>
        <mtd columnalign="right">
          <mn>
            6
          </mn>
        </mtd>
      </mtr>
    </mtable>'
  ],
  [
    'issue #33',
    '\\begin{bmatrix}
   a_{1,1} & a_{1,2} & \\cdots & a_{1,n} \\\\
   a_{2,1} & a_{2,2} & \\cdots & a_{2,n} \\\\
   \\vdots  & \\vdots  & \\ddots & \\vdots  \\\\
   a_{m,1} & a_{m,2} & \\cdots & a_{m,n}
  \\end{bmatrix}',
    '<mo>
  &#x0005B;
</mo>
<mtable>
  <mtr>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mn>
            1
          </mn>
          <mi>
            ,
          </mi>
          <mn>
            1
          </mn>
        </mrow>
      </msub>
    </mtd>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mn>
            1
          </mn>
          <mi>
            ,
          </mi>
          <mn>
            2
          </mn>
        </mrow>
      </msub>
    </mtd>
    <mtd>
      <mo>
        &#x022EF;
      </mo>
    </mtd>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mn>
            1
          </mn>
          <mi>
            ,
          </mi>
          <mi>
            n
          </mi>
        </mrow>
      </msub>
    </mtd>
  </mtr>
  <mtr>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mn>
            2
          </mn>
          <mi>
            ,
          </mi>
          <mn>
            1
          </mn>
        </mrow>
      </msub>
    </mtd>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mn>
            2
          </mn>
          <mi>
            ,
          </mi>
          <mn>
            2
          </mn>
        </mrow>
      </msub>
    </mtd>
    <mtd>
      <mo>
        &#x022EF;
      </mo>
    </mtd>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mn>
            2
          </mn>
          <mi>
            ,
          </mi>
          <mi>
            n
          </mi>
        </mrow>
      </msub>
    </mtd>
  </mtr>
  <mtr>
    <mtd>
      <mo>
        &#x022EE;
      </mo>
    </mtd>
    <mtd>
      <mo>
        &#x022EE;
      </mo>
    </mtd>
    <mtd>
      <mo>
        &#x022F1;
      </mo>
    </mtd>
    <mtd>
      <mo>
        &#x022EE;
      </mo>
    </mtd>
  </mtr>
  <mtr>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mi>
            m
          </mi>
          <mi>
            ,
          </mi>
          <mn>
            1
          </mn>
        </mrow>
      </msub>
    </mtd>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mi>
            m
          </mi>
          <mi>
            ,
          </mi>
          <mn>
            2
          </mn>
        </mrow>
      </msub>
    </mtd>
    <mtd>
      <mo>
        &#x022EF;
      </mo>
    </mtd>
    <mtd>
      <msub>
        <mi>
          a
        </mi>
        <mrow>
          <mi>
            m
          </mi>
          <mi>
            ,
          </mi>
          <mi>
            n
          </mi>
        </mrow>
      </msub>
    </mtd>
  </mtr>
</mtable>
<mo>
  &#x0005D;
</mo>'
  ],
  [
    'issue #42',
    '\\sqrt { ( - 25 ) ^ { 2 } } = \\pm 25',
    '<msqrt>
      <mrow>
        <msup>
          <mrow>
            <mo stretchy="false">
              &#x00028;
            </mo>
            <mo>
              &#x02212;
            </mo>
            <mn>
              25
            </mn>
            <mo stretchy="false">
              &#x00029;
            </mo>
          </mrow>
          <mrow>
            <mn>
              2
            </mn>
          </mrow>
        </msup>
      </mrow>
    </msqrt>
    <mo>
      &#x0003D;
    </mo>
    <mi>
      &#x000B1;
    </mi>
    <mn>
      25
    </mn>'
  ],
  [
    'issue #45 lt',
    '2 < 5',
    '<mn>2</mn><mo>&lt;</mo><mn>5</mn>'
  ],
  [
    'issue #45 gt',
    '2 > 5',
    '<mn>2</mn><mo>&gt;</mo><mn>5</mn>'
  ],
  ['issue #45 amp', '&', '<mo>&amp;</mo>'],
  [
    'issue #44',
    '\\left(- x^{3} + 5\\right)^{5}',
    '<msup>
      <mrow>
        <mo stretchy="true" fence="true" form="prefix">
          &#x00028;
        </mo>
        <mrow>
          <mo>
            &#x02212;
          </mo>
          <msup>
            <mi>
              x
            </mi>
            <mrow>
              <mn>
                3
              </mn>
            </mrow>
          </msup>
          <mo>
            &#x0002B;
          </mo>
          <mn>
            5
          </mn>
        </mrow>
        <mo stretchy="true" fence="true" form="postfix">
          &#x00029;
        </mo>
      </mrow>
      <mrow>
        <mn>
          5
        </mn>
      </mrow>
    </msup>'
  ],
  ['issue #51', '\\mathbb{R}', '<mi>&#x0211D;</mi>'],
  [
    'issue #60-1',
    '\\mathrm{...}',
    '<mrow><mo>.</mo><mo>.</mo><mo>.</mo></mrow>'
  ],
  [
    'issue #52',
    '\\bar{z_1} = z_2',
    '<mover>
      <mrow>
        <msub>
          <mi>
            z
          </mi>
          <mn>
            1
          </mn>
        </msub>
      </mrow>
      <mo stretchy="true">
        &#x000AF;
      </mo>
    </mover>
    <mo>
      &#x0003D;
    </mo>
    <msub>
      <mi>
        z
      </mi>
      <mn>
        2
      </mn>
    </msub>'
  ],
  [
    'issue #60-2',
    '\\mathrm{...}+\\mathrm{...}',
    '<mrow><mo>.</mo><mo>.</mo><mo>.</mo></mrow><mo>&#x0002B;</mo><mrow><mo>.</mo><mo>.</mo><mo>.</mo></mrow>'
  ],
  [
    'issue #61',
    '\\frac{x + 4}{x + \\frac{123 \\left(\\sqrt{x} + 5\\right)}{x + 4} - 8}',
    '<mfrac>
        <mrow><mi>x</mi><mo>&#x0002B;</mo><mn>4</mn></mrow>
        <mrow>
          <mi>x</mi>
          <mo>&#x0002B;</mo>
          <mfrac>
            <mrow>
              <mn>123</mn>
              <mrow>
                <mo stretchy="true" fence="true" form="prefix">&#x00028;</mo>
                <mrow>
                  <msqrt><mrow><mi>x</mi></mrow></msqrt>
                  <mo>&#x0002B;</mo>
                  <mn>5</mn>
                </mrow>
                <mo stretchy="true" fence="true" form="postfix">&#x00029;</mo>
              </mrow>
            </mrow>
            <mrow><mi>x</mi><mo>&#x0002B;</mo><mn>4</mn></mrow>
          </mfrac>
          <mo>&#x02212;</mo>
          <mn>8</mn>
        </mrow>
      </mfrac>
      '
  ],
  [
    'issue #63',
    '\\sqrt {\\sqrt {\\left( x^{3}\\right) + v}}',
    '<msqrt>
      <mrow>
        <msqrt>
          <mrow>
            <mrow>
              <mo stretchy="true" fence="true" form="prefix">
                &#x00028;
              </mo>
              <mrow>
                <msup>
                  <mi>
                    x
                  </mi>
                  <mrow>
                    <mn>
                      3
                    </mn>
                  </mrow>
                </msup>
              </mrow>
              <mo stretchy="true" fence="true" form="postfix">
                &#x00029;
              </mo>
            </mrow>
            <mo>
              &#x0002B;
            </mo>
            <mi>
              v
            </mi>
          </mrow>
        </msqrt>
      </mrow>
    </msqrt>'
  ],
  [
    'empty subscript',
    '1_{}',
    '<msub><mn>1</mn><mrow></mrow></msub>'
  ],
  [
    '\\Bmatrix',
    '\\begin{Bmatrix}\\end{Bmatrix}',
    '<mo>&#x0007B;</mo><mtable></mtable><mo>&#x0007D;</mo>'
  ],
  [
    '\\vmatrix',
    '\\begin{vmatrix}\\end{vmatrix}',
    '<mo>&#x0007C;</mo><mtable></mtable><mo>&#x0007C;</mo>'
  ],
  [
    '\\Vmatrix',
    '\\begin{Vmatrix}\\end{Vmatrix}',
    '<mo>&#x02016;</mo><mtable></mtable><mo>&#x02016;</mo>'
  ],
  [
    'command inside matrix',
    '\\begin{matrix}1^2\\end{matrix}',
    '<mtable><mtr><mtd><msup><mn>1</mn><mn>2</mn></msup></mtd></mtr></mtable>'
  ],
  ['\\e', '\\e', '<mi>\\e</mi>'],
  [
    'issue #77',
    '\\left[\\begin{matrix}1 & 0 & 0 & 0\\\\0 & 1 & 0 & 0\\\\0 & 0 & 1 & 0\\\\0 & 0 & 0 & 1\\end{matrix}\\right]',
    '<mrow>
      <mo stretchy="true" fence="true" form="prefix">
        [
      </mo>
      <mrow>
        <mtable>
          <mtr>
            <mtd>
              <mn>
                1
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                1
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                1
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
          </mtr>
          <mtr>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                0
              </mn>
            </mtd>
            <mtd>
              <mn>
                1
              </mn>
            </mtd>
          </mtr>
        </mtable>
      </mrow>
      <mo stretchy="true" fence="true" form="postfix">
        ]
      </mo>
    </mrow>'
  ],
  ['logarithm', '\\log{x}', '<mi>log</mi><mrow><mi>x</mi></mrow>'],
  [
    'logarithm with base',
    '\\log_2{x}',
    '<msub><mi>log</mi><mn>2</mn></msub><mrow><mi>x</mi></mrow>'
  ],
  [
    'exponent without base works',
    '^3',
    '<msup><mi></mi><mn>3</mn></msup>'
  ],
  [
    'limit at plus infinity',
    '\\lim_{x \\to +\\infty} f(x)',
    '<munder>
      <mo>
        lim
      </mo>
      <mrow>
        <mi>
          x
        </mi>
        <mo>
          &#x02192;
        </mo>
        <mo>
          &#x0002B;
        </mo>
        <mo>
          &#x0221E;
        </mo>
      </mrow>
    </munder>
    <mi>
      f
    </mi>
    <mo stretchy="false">
      &#x00028;
    </mo>
    <mi>
      x
    </mi>
    <mo stretchy="false">
      &#x00029;
    </mo>'
  ],
  [
    'inf',
    '\\inf_{x > s}f(x)',
    '<munder><mo>inf</mo><mrow><mi>x</mi><mo>&gt;</mo><mi>s</mi></mrow></munder><mi>f</mi><mo stretchy="false">&#x00028;</mo><mi>x</mi><mo stretchy="false">&#x00029;</mo>'
  ],
  [
    'issue #76',
    '\\int\\limits_{0}^{\\pi}',
    '<munderover>
        <mo>&#x0222B;</mo>
        <mrow>
          <mn>0</mn>
        </mrow>
        <mrow>
          <mi>&#x003C0;</mi>
        </mrow>
      </munderover>'
  ],
  [
    'issue #75 - 1 row',
    '\\substack{ \\xi{2}=g{\\left(x \\right)}}',
    '<mstyle scriptlevel="1">
             <mtable>
               <mtr>
                 <mtd>
                   <mi>
                     &#x003BE;
                   </mi>
                   <mn>
                     2
                   </mn>
                   <mo>
                     &#x0003D;
                   </mo>
                   <mi>
                     g
                   </mi>
                   <mrow>
                     <mo stretchy="true" fence="true" form="prefix">
                       &#x00028;
                     </mo>
                     <mrow>
                       <mi>
                         x
                       </mi>
                     </mrow>
                     <mo stretchy="true" fence="true" form="postfix">
                       &#x00029;
                     </mo>
                   </mrow>
                 </mtd>
               </mtr>
             </mtable>
           </mstyle>'
  ],
  [
    'issue #75 - 2 rows',
    '\\sum_{\\substack{1\\le i\\le n\\\\ i\\ne j}}',
    '<munder>
      <mo>
        &#x02211;
      </mo>
      <mrow>
        <mstyle scriptlevel="1">
          <mtable>
            <mtr>
              <mtd>
                <mn>
                  1
                </mn>
                <mo>
                  &#x02264;
                </mo>
                <mi>
                  i
                </mi>
                <mo>
                  &#x02264;
                </mo>
                <mi>
                  n
                </mi>
              </mtd>
            </mtr>
            <mtr>
              <mtd>
                <mi>
                  i
                </mi>
                <mo>
                  &#x02260;
                </mo>
                <mi>
                  j
                </mi>
              </mtd>
            </mtr>
          </mtable>
        </mstyle>
      </mrow>
    </munder>'
  ],
  [
    'issue #91',
    '\\tan x + \\sec x + \\cos x + \\sin x + \\cot x + \\csc x',
    '<mi>tan</mi><mi>x</mi><mo>&#x0002B;</mo>
    <mi>sec</mi><mi>x</mi><mo>&#x0002B;</mo>
    <mi>cos</mi><mi>x</mi><mo>&#x0002B;</mo>
    <mi>sin</mi><mi>x</mi><mo>&#x0002B;</mo>
    <mi>cot</mi><mi>x</mi><mo>&#x0002B;</mo>
    <mi>csc</mi><mi>x</mi>'
  ],
  [
    'issue #98',
    'p_{\\max}',
    '<msub><mi>p</mi><mrow><mo>max</mo></mrow></msub>'
  ],
  [
    'issue #100',
    '\\overrightarrow {a}',
    '<mover><mrow><mi>a</mi></mrow><mo stretchy="true">&#x02192;</mo></mover>'
  ],
  [
    'array #1',
    '\\left( \\begin{array}{c}
    N_{xx}\\\\
    N_{yy}\\\\
    N_{xy}\\\\
    M_{xx}\\\\
    M_{yy}\\\\
    M_{xy} \\end{array} \\right)',
    '<mrow>
    <mo stretchy="true" fence="true" form="prefix">
      &#x00028;
    </mo>
    <mrow>
      <mtable>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                N
              </mi>
              <mrow>
                <mi>
                  x
                </mi>
                <mi>
                  x
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                N
              </mi>
              <mrow>
                <mi>
                  y
                </mi>
                <mi>
                  y
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                N
              </mi>
              <mrow>
                <mi>
                  x
                </mi>
                <mi>
                  y
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                M
              </mi>
              <mrow>
                <mi>
                  x
                </mi>
                <mi>
                  x
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                M
              </mi>
              <mrow>
                <mi>
                  y
                </mi>
                <mi>
                  y
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                M
              </mi>
              <mrow>
                <mi>
                  x
                </mi>
                <mi>
                  y
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
      </mtable>
    </mrow>
    <mo stretchy="true" fence="true" form="postfix">
      &#x00029;
    </mo>
  </mrow>'
  ],
  [
    'array #5',
    '\\begin{array}{cc}
    \\left(    \\begin{array}{ccccccc}
            & & & & & & \\\\
            & +k & & & & -k  \\\\
            & & & & & & \\\\
            & & & & & & \\\\
            & & & & & & \\\\
            & -k & & & & +k
        \\end{array}  \\right)   &
             \\begin{array}{cc}
                      & \\\\
                      \\cdots & \\mbox{degree of freedom 1, node 1} \\\\
                      & \\\\
                      & \\\\
                      & \\\\
                      \\cdots & \\mbox{degree of freedom 2, node 2}
             \\end{array}      \\\\
                         & \\\\
            \\begin{array}{cccccc}
               \\vdots & & & & & \\vdots
         \\end{array}  & \\\\
         \\begin{array}{cccc}
    & \\mbox{degree of}  & \\mbox{degree of}  & \\\\
    & \\mbox{freedom 1,} & \\mbox{freedom 2,} & \\\\
    & \\mbox{node 1} & \\mbox{node 2}  &
        \\end{array}    &
    \\end{array}',
    '<mtable>
    <mtr>
      <mtd columnalign="center">
        <mo stretchy="true" fence="true" form="prefix">
          &#x00028;
        </mo>
        <mrow>
          <mtable>
            <mtr>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
            </mtr>
            <mtr>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mo>
                  &#x0002B;
                </mo>
                <mi>
                  k
                </mi>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mo>
                  &#x02212;
                </mo>
                <mi>
                  k
                </mi>
              </mtd>
            </mtr>
            <mtr>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
            </mtr>
            <mtr>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
            </mtr>
            <mtr>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
            </mtr>
            <mtr>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mo>
                  &#x02212;
                </mo>
                <mi>
                  k
                </mi>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mi/>
              </mtd>
              <mtd columnalign="center">
                <mo>
                  &#x0002B;
                </mo>
                <mi>
                  k
                </mi>
              </mtd>
            </mtr>
          </mtable>
        </mrow>
        <mo stretchy="true" fence="true" form="postfix">
          &#x00029;
        </mo>
      </mtd>
      <mtd columnalign="center">
        <mtable>
          <mtr>
            <mtd columnalign="center">
              <mi/>
            </mtd>
            <mtd columnalign="center">
              <mi/>
            </mtd>
          </mtr>
          <mtr>
            <mtd columnalign="center">
              <mo>
                &#x022EF;
              </mo>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                degree of freedom 1, node 1
              </mtext>
            </mtd>
          </mtr>
          <mtr>
            <mtd columnalign="center">
              <mi/>
            </mtd>
            <mtd columnalign="center">
              <mi/>
            </mtd>
          </mtr>
          <mtr>
            <mtd columnalign="center">
              <mi/>
            </mtd>
            <mtd columnalign="center">
              <mi/>
            </mtd>
          </mtr>
          <mtr>
            <mtd columnalign="center">
              <mi/>
            </mtd>
            <mtd columnalign="center">
              <mi/>
            </mtd>
          </mtr>
          <mtr>
            <mtd columnalign="center">
              <mo>
                &#x022EF;
              </mo>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                degree of freedom 2, node 2
              </mtext>
            </mtd>
          </mtr>
        </mtable>
      </mtd>
    </mtr>
    <mtr>
      <mtd columnalign="center">
        <mi/>
      </mtd>
      <mtd columnalign="center">
        <mi/>
      </mtd>
    </mtr>
    <mtr>
      <mtd columnalign="center">
        <mtable>
          <mtr>
            <mtd>
              <mo>
                &#x022EE;
              </mo>
            </mtd>
            <mtd>
              <mi/>
            </mtd>
            <mtd>
              <mi/>
            </mtd>
            <mtd>
              <mi/>
            </mtd>
            <mtd>
              <mi/>
            </mtd>
            <mtd>
              <mo>
                &#x022EE;
              </mo>
            </mtd>
          </mtr>
        </mtable>
      </mtd>
      <mtd columnalign="center">
        <mi/>
      </mtd>
    </mtr>
    <mtr>
      <mtd columnalign="center">
        <mtable>
          <mtr>
            <mtd columnalign="center">
              <mi/>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                degree of
              </mtext>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                degree of
              </mtext>
            </mtd>
            <mtd columnalign="center">
              <mi/>
            </mtd>
          </mtr>
          <mtr>
            <mtd columnalign="center">
              <mi/>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                freedom 1,
              </mtext>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                freedom 2,
              </mtext>
            </mtd>
            <mtd columnalign="center">
              <mi/>
            </mtd>
          </mtr>
          <mtr>
            <mtd columnalign="center">
              <mi/>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                node 1
              </mtext>
            </mtd>
            <mtd columnalign="center">
              <mtext>
                node 2
              </mtext>
            </mtd>
            <mtd columnalign="center">
              <mi/>
            </mtd>
          </mtr>
        </mtable>
      </mtd>
      <mtd columnalign="center">
        <mi/>
      </mtd>
    </mtr>
  </mtable>'
  ],
  [
    'array #9',
    File.read('./spec/fixtures/array/h.tex'),
    '<mrow>
    <mo stretchy="true" fence="true" form="prefix">
      &#x00028;
    </mo>
    <mrow>
      <mtable>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                V
              </mi>
              <mi>
                x
              </mi>
            </msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                V
              </mi>
              <mi>
                y
              </mi>
            </msub>
          </mtd>
        </mtr>
      </mtable>
    </mrow>
    <mo stretchy="true" fence="true" form="postfix">
      &#x00029;
    </mo>
  </mrow>
  <mo>
    &#x0003D;
  </mo>
  <msub>
    <mi>
      h
    </mi>
    <mi>
      s
    </mi>
  </msub>
  <mspace width="0.167em"/>
  <msub>
    <mi>
      D
    </mi>
    <mi>
      s
    </mi>
  </msub>
  <mspace width="0.167em"/>
  <mrow>
    <mo stretchy="true" fence="true" form="prefix">
      &#x00028;
    </mo>
    <mrow>
      <mtable>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                &#x003B5;
              </mi>
              <mrow>
                <mi>
                  x
                </mi>
                <mi>
                  z
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
        <mtr>
          <mtd columnalign="center">
            <msub>
              <mi>
                &#x003B5;
              </mi>
              <mrow>
                <mi>
                  y
                </mi>
                <mi>
                  z
                </mi>
              </mrow>
            </msub>
          </mtd>
        </mtr>
      </mtable>
    </mrow>
    <mo stretchy="true" fence="true" form="postfix">
      &#x00029;
    </mo>
  </mrow>'
  ],
  [
    'array #9',
    File.read('./spec/fixtures/matrix/pmatrix.tex'),
    '<mo>
    &#x00028;
  </mo>
  <mtable>
    <mtr>
      <mtd>
        <msub>
          <mover accent="true">
            <mi>
              e
            </mi>
            <mo stretchy="false">
              &#x00302;
            </mo>
          </mover>
          <mrow>
            <mi>
              &#x003BE;
            </mi>
          </mrow>
        </msub>
      </mtd>
    </mtr>
    <mtr>
      <mtd>
        <msub>
          <mover accent="true">
            <mi>
              e
            </mi>
            <mo stretchy="false">
              &#x00302;
            </mo>
          </mover>
          <mrow>
            <mi>
              &#x003B7;
            </mi>
          </mrow>
        </msub>
      </mtd>
    </mtr>
    <mtr>
      <mtd>
        <msub>
          <mover accent="true">
            <mi>
              e
            </mi>
            <mo stretchy="false">
              &#x00302;
            </mo>
          </mover>
          <mrow>
            <mi>
              &#x003B6;
            </mi>
          </mrow>
        </msub>
      </mtd>
    </mtr>
  </mtable>
  <mo>
    &#x00029;
  </mo>
  <mo>
    &#x0003D;
  </mo>
  <mi>
    &#x1D413;
  </mi>
  <mo>
    &#x00028;
  </mo>
  <mtable>
    <mtr>
      <mtd>
        <msub>
          <mover accent="true">
            <mi>
              e
            </mi>
            <mo stretchy="false">
              &#x00302;
            </mo>
          </mover>
          <mi>
            x
          </mi>
        </msub>
      </mtd>
    </mtr>
    <mtr>
      <mtd>
        <msub>
          <mover accent="true">
            <mi>
              e
            </mi>
            <mo stretchy="false">
              &#x00302;
            </mo>
          </mover>
          <mi>
            y
          </mi>
        </msub>
      </mtd>
    </mtr>
    <mtr>
      <mtd>
        <msub>
          <mover accent="true">
            <mi>
              e
            </mi>
            <mo stretchy="false">
              &#x00302;
            </mo>
          </mover>
          <mi>
            z
          </mi>
        </msub>
      </mtd>
    </mtr>
  </mtable>
  <mo>
    &#x00029;
  </mo>
  <mi>
    ,
  </mi>'
  ]
].freeze

RSpec.describe Latexmath::Converter do
  CONVERTER_PARAMS.each do |param|
    it (param[0]).to_s do
      tokens = Latexmath::Tokenizer.new(param[1]).tokenize
      aggr = Latexmath::Aggregator.new(tokens).aggregate
      xml = <<~EOQ
        <math xmlns="http://www.w3.org/1998/Math/MathML" display="block">
          <mrow>#{param[2]}</mrow>
        </math>
      EOQ

      expect(Latexmath::Converter.new(aggr).convert).to be_equivalent_to(xml)
    end
  end

  records = Dir.glob('spec/fixtures/*/*.tex')

  records.each do |file|
    it file do
      tex = File.read("./#{file}")
      tokens = Latexmath::Tokenizer.new(tex).tokenize
      aggr = Latexmath::Aggregator.new(tokens).aggregate

      File.write("./#{file}.html", Latexmath::Converter.new(aggr).convert)
    end
  end
end
