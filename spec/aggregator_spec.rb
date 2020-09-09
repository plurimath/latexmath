AGGREGATOR_PARAMS = [
  ['alphabets', 'abcdef', 'abcdef'.chars.to_a],
  ['empty group', '{{}}', [[[]]]],
  ['numbers', '445454', ['445454']],
  ['numbers with decimal', '12.56', ['12.56']],
  ['numbers and alphabets', '5x', '5x'.chars.to_a],
  ['decimals and alphabets', '5.8x', ['5.8', 'x']],
  ['string with spaces', '3 x', %w[3 x]],
  ['operators', '+-*/=()[]_^{}', '+-*/=()[]_^{}'.chars.to_a],
  [
    'numbers, alphabets and operators',
    '3 + 5x - 5y = 7',
    ['3', '+', '5', 'x', '-', '5', 'y', '=', '7']
  ],
  ['symbols', '\\alpha\\beta', ['\\alpha', '\\beta']],
  ['symbols appended with number', '\\frac2x', ['\\frac', '2', 'x']],
  ['single group', '{a}', [['a']]],
  ['multiple groups', '{a}{b}', [['a'], ['b']]],
  ['inner group', '{a+{b}}', [['a', '+', ['b']]]],
  ['subscript #1', 'a_b', %w[_ a b]],
  ['subscript #2', '{a_b}', [%w[_ a b]]],
  ['subscript #3', '1_2', %w[_ 1 2]],
  ['subscript #4', '1.2_2', ['_', '1.2', '2']],
  ['superscript #1', 'a^b', ['^', 'a', 'b']],
  ['superscript #2', '{a^b}', [['^', 'a', 'b']]],
  ['superscript #3', 'a^{i+1}_3', ['_^', 'a', '3', ['i', '+', '1']]],
  ['subscript and superscript #1', 'a_b^c', ['_^', 'a', 'b', 'c']],
  ['subscript and superscript #2', 'a^b_c', ['_^', 'a', 'c', 'b']],
  ['root', '\\sqrt[3]{2}', ['\\root', ['2'], ['3']]],
  ['matrix #1', '\\matrix{a & b \\\\ c & d}', ['\\matrix', [%w[a b], %w[c d]]]],
  [
    'matrix #2',
    '\\begin{matrix}a & b \\\\ c & d \\end{matrix}',
    ['\\matrix', [%w[a b], %w[c d]]]
  ],
  ['fraction #1', '\\frac{1}{2}', ['\\frac', ['1'], ['2']]],
  ['fraction #2', '1 \\over 2', ['\\frac', ['1'], ['2']]],
  ['fraction #3', '{1 \\over 2}', [['\\frac', ['1'], ['2']]]],
  ['fraction #4', "L' \\over {1\\over2}", ['\\frac', ['L', "'"], [['\\frac', ['1'], ['2']]]]],
  ['null delimiter #1', '\\left\\{\\right.', [['\\left', '\\{', '\\right', '.']]],
  [
    'null delimiter #2',
    '\\left\\{ \\begin{array} { l } { 3x - 5y + 4z = 0} \\\\ { x - y + 8z = 0} \\\\ { 2x - 6y + z = 0} '\
    '\\end{array}\\right.',
    [
      [
        '\\left',
        '\\{',
        [
          '\\array',
          'l',
          [
            [['3', 'x', '-', '5', 'y', '+', '4', 'z', '=', '0']],
            [['x', '-', 'y', '+', '8', 'z', '=', '0']],
            [['2', 'x', '-', '6', 'y', '+', 'z', '=', '0']]
          ]
        ],
        '\\right',
        '.'
      ]
    ]
  ],
  [
    'matrix with alignment',
    '\\begin{matrix*}[r]a & b \\\\ c & d \\end{matrix*}',
    ['\\matrix*', 'r', [%w[a b], %w[c d]]]
  ],
  [
    'matrix with empty alignment',
    '\\begin{matrix*}[]a & b \\\\ c & d \\end{matrix*}',
    ['\\matrix*', [%w[a b], %w[c d]]]
  ],
  [
    'matrix with negative sign',
    '\\begin{matrix}-a & b \\\\ c & d \\end{matrix}',
    ['\\matrix', [[['-', 'a'], 'b'], %w[c d]]]
  ],
  [
    'matrix with just negative sign #1',
    '\\begin{matrix}-\\end{matrix}',
    ['\\matrix', ['-']]
  ],
  [
    'complex matrix',
    '\\begin{matrix}a_{1} & b_{2} \\\\ c_{3} & d_{4} \\end{matrix}',
    [
      '\\matrix',
      [
        [['_', 'a', ['1']], ['_', 'b', ['2']]],
        [['_', 'c', ['3']], ['_', 'd', ['4']]]
      ]
    ]
  ],
  [
    'simple array',
    '\\begin{array}{cc} 1 & 2 \\\\ 3 & 4 \\end{array}',
    ['\\array', 'cc', [%w[1 2], %w[3 4]]]
  ],
  [
    'issue #33',
    "\\begin{bmatrix}
   a_{1,1} & a_{1,2} & \\cdots & a_{1,n} \\\\
   a_{2,1} & a_{2,2} & \\cdots & a_{2,n} \\\\
   \\vdots  & \\vdots  & \\ddots & \\vdots  \\\\
   a_{m,1} & a_{m,2} & \\cdots & a_{m,n}
  \\end{bmatrix}",
    [
      '\\bmatrix',
      [
        [
          ['_', 'a', ['1', ',', '1']],
          ['_', 'a', ['1', ',', '2']],
          '\\cdots',
          ['_', 'a', ['1', ',', 'n']]
        ],
        [
          ['_', 'a', ['2', ',', '1']],
          ['_', 'a', ['2', ',', '2']],
          '\\cdots',
          ['_', 'a', ['2', ',', 'n']]
        ],
        ['\\vdots', '\\vdots', '\\ddots', '\\vdots'],
        [
          ['_', 'a', ['m', ',', '1']],
          ['_', 'a', ['m', ',', '2']],
          '\\cdots',
          ['_', 'a', ['m', ',', 'n']]
        ]
      ]
    ]
  ],
  [
    'issue #42',
    '\\sqrt { ( - 25 ) ^ { 2 } } = \\pm 25',
    ['\\sqrt', ['^', ['(', '-', '25', ')'], ['2']], '=', '\\pm', '25']
  ],
  [
    'issue #44',
    '\\left(- x^{3} + 5\\right)^{5}',
    ['^', ['\\left', '(', ['-', '^', 'x', ['3'], '+', '5'], '\\right', ')'], ['5']]
  ],
  [
    'issue #55',
    '\\begin{array}{rcl}ABC&=&a\\\\A&=&abc\\end{array}',
    ['\\array', 'rcl', [[%w[A B C], '=', 'a'], ['A', '=', %w[a b c]]]]
  ],
  [
    'array with horizontal line',
    '\\begin{array}{cr} 1 & 2 \\\\ 3 & 4 \\\\ \\hline 5 & 6 \\end{array}',
    ['\\array', 'cr', [%w[1 2], %w[3 4], ['\\hline', '5', '6']]]
  ],
  [
    'array with horizontal lines',
    '\\begin{array}{cr} 1 & 2 \\\\ \\hline 3 & 4 \\\\ \\hline 5 & 6 \\end{array}',
    ['\\array', 'cr', [%w[1 2], ['\\hline', '3', '4'], ['\\hline', '5', '6']]]
  ],
  ['issue #60', '\\mathrm{...}', ['\\mathrm', ['.', '.', '.']]],
  [
    'issue #61',
    '\\frac{x + 4}{x + \\frac{123 \\left(\\sqrt{x} + 5\\right)}{x + 4} - 8}',
    [
      '\\frac',
      ['x', '+', '4'],
      [
        'x',
        '+',
        '\\frac',
        ['123', ['\\left', '(', ['\\sqrt', ['x'], '+', '5'], '\\right', ')']],
        ['x', '+', '4'],
        '-',
        '8'
      ]
    ]
  ],
  [
    'issue #63',
    '\\sqrt {\\sqrt {\\left( x^{3}\\right) + v}}',
    [
      '\\sqrt',
      ['\\sqrt', [['\\left', '(', ['^', 'x', ['3']], '\\right', ')'], '+', 'v']]
    ]
  ],
  [
    'group after \\right',
    '\\left(x\\right){5}',
    [['\\left', '(', ['x'], '\\right', ')'], ['5']]
  ],
  ['empty nth root', '\\sqrt[3]{}', ['\\root', '', ['3']]],
  ['empty subscript', '1_{}', ['_', '1', []]],
  ['empty array', '\\array{}', ['\\array', []]],
  ['empty array with empty group', '\\array{{}}', ['\\array', []]],
  [
    'issue #77',
    '\\left[\\begin{matrix}1 & 0 & 0 & 0\\\\0 & 1 & 0 & 0\\\\0 & 0 & 1 & 0\\\\0 & 0 & 0 & 1\\end{matrix}\\right]',
    [
      [
        '\\left',
        '[',
        [
          '\\matrix',
          [
            %w[1 0 0 0],
            %w[0 1 0 0],
            %w[0 0 1 0],
            %w[0 0 0 1]
          ]
        ],
        '\\right',
        ']'
      ]
    ]
  ],
  [
    'issue #78',
    'x^{x^{x^{x}}} \\left(x^{x^{x}} \\left(x^{x} \\left(\\log{\\left(x \\right)} + 1\\right) \\log{\\left(x \\right)} + '\
    '\\frac{x^{x}}{x}\\right) \\log{\\left(x \\right)} + \\frac{x^{x^{x}}}{x}\\right)',
    [
      '^',
      'x',
      ['^', 'x', ['^', 'x', ['x']]],
      [
        '\\left',
        '(',
        [
          '^',
          'x',
          ['^', 'x', ['x']],
          [
            '\\left',
            '(',
            [
              '^',
              'x',
              ['x'],
              [
                '\\left',
                '(',
                [
                  '\\log',
                  [['\\left', '(', ['x'], '\\right', ')']],
                  '+',
                  '1'
                ],
                '\\right',
                ')'
              ],
              '\\log',
              [['\\left', '(', ['x'], '\\right', ')']],
              '+',
              '\\frac',
              ['^', 'x', ['x']],
              ['x']
            ],
            '\\right',
            ')'
          ],
          '\\log',
          [['\\left', '(', ['x'], '\\right', ')']],
          '+',
          '\\frac',
          ['^', 'x', ['^', 'x', ['x']]],
          ['x']
        ],
        '\\right',
        ')'
      ]
    ]
  ],
  ['logarithm with base', '\\log_2{x}', ['_', '\\log', '2', ['x']]],
  ['issue #79 - empty root', '\\sqrt[]{3}', ['\\sqrt', ['3']]],
  [
    'issue #79 - exponent after fraction',
    '\\frac{3}{\\frac{1}{2}{x}^{2}}',
    ['\\frac', ['3'], ['\\frac', ['1'], ['2'], '^', ['x'], ['2']]]
  ],
  [
    'issue #79',
    '\\frac{3}{\\frac{1}{2}{x}^{2}-\\frac{3\\sqrt[]{3}}{2}x+3}',
    [
      '\\frac',
      ['3'],
      [
        '\\frac',
        ['1'],
        ['2'],
        '^',
        ['x'],
        ['2'],
        '-',
        '\\frac',
        ['3', '\\sqrt', ['3']],
        ['2'],
        'x',
        '+',
        '3'
      ]
    ]
  ],
  ['exponent without base works', '^3', ['^', '', '3']],
  [
    'limit at plus infinity',
    '\\lim_{x \\to +\\infty} f(x)',
    ['\\lim', ['x', '\\to', '+', '\\infty'], 'f', '(', 'x', ')']
  ],
  ['inf', '\\inf_{x > s}f(x)', ['\\inf', ['x', '>', 's'], 'f', '(', 'x', ')']],
  [
    'sup',
    '\\sup_{x \\in \\mathbb{R}}f(x)',
    ['\\sup', ['x', '\\in', '&#x0211D;'], 'f', '(', 'x', ')']
  ],
  [
    'max',
    '\\max_{x \\in \\[a,b\\]}f(x)',
    ['\\max', ['x', '\\in', '\\[', 'a', ',', 'b', '\\]'], 'f', '(', 'x', ')']
  ],
  [
    'min',
    '\\min_{x \\in \\[\\alpha,\\beta\\]}f(x)',
    [
      '\\min',
      ['x', '\\in', '\\[', '\\alpha', ',', '\\beta', '\\]'],
      'f',
      '(',
      'x',
      ')'
    ]
  ],
  ['issue #76', '\\int\\limits_{0}^{\\pi}', ['\\limits', '\\int', ['0'], ['\\pi']]],
  [
    'issue #75',
    '\\sum_{\\substack{1\\le i\\le n\\\\ i\\ne j}}',
    [
      '_',
      '\\sum',
      ['\\substack', [['1', '\\le', 'i', '\\le', 'n'], ['i', '\\ne', 'j']]]
    ]
  ],
  ['issue #94', '\\mathrm{AA}', ['\\mathrm', %w[A A]]],
  [
    'issue #96',
    '(1+(x-y)^{2})',
    ['(', '1', '+', '^', ['(', 'x', '-', 'y', ')'], ['2'], ')']
  ],
  ['issue #98', 'p_{\\max}', ['_', 'p', ['\\max']]],
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
    ["\\array","cc",
      [
        [
          [
            "\\left","(",
            ["\\array","ccccccc",
              [
                [nil,nil,nil,nil,nil,nil,nil],
                [nil,["+","k"],nil,nil,nil,["-","k"]],
                [nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil],
                [nil,nil,nil,nil,nil,nil,nil],
                [nil,["-","k"],nil,nil,nil,["+","k"]]]
            ],
            "\\right",")"
          ],
          ["\\array","cc",
            [
              [nil,nil],
              ["\\cdots","\\mbox{degree of freedom 1, node 1}"],
              [nil,nil],
              [nil,nil],
              [nil,nil],
              ["\\cdots","\\mbox{degree of freedom 2, node 2}"]
            ]]
        ],
        [nil,nil],
        [
          ["\\array","cccccc",
            ["\\vdots",nil,nil,nil,nil,"\\vdots"]
          ],
          nil
        ],
        [
          ["\\array","cccc",
            [
              [nil,"\\mbox{degree of}","\\mbox{degree of}",nil],
              [nil,"\\mbox{freedom 1,}","\\mbox{freedom 2,}",nil],
              [nil,"\\mbox{node 1}","\\mbox{node 2}",nil]
            ]
          ],
          nil
        ]
      ]
    ]
  ],
  [
    'split #1',
    '\begin{split}
    C_L &= {L \over {1\over2} \rho_\textrm{ref} q_\textrm{ref}^2 S} \\ \\
    C_D &= {D \over {1\over2} \rho_\textrm{ref} q_\textrm{ref}^2 S} \\ \\
    \vec{C}_M &= {\vec{M} \over {1\over2} \rho_\textrm{ref} q_\textrm{ref}^2 c_\textrm{ref} S_\textrm{ref}},
    \end{split}',
    ["\\split",[["_","C","L"],["=",["\\frac",["L"],[["\\frac",["1"],["2"]],"_","\\rho","\\textrm{ref}","_^","q","\\textrm{ref}","2","S"]],"\\","\\","_","C","D"],["=",["\\frac",["D"],[["\\frac",["1"],["2"]],"_","\\rho","\\textrm{ref}","_^","q","\\textrm{ref}","2","S"]],"\\","\\","_","\\vec{C}","M"],["=",["\\frac",["\\vec{M}"],[["\\frac",["1"],["2"]],"_","\\rho","\\textrm{ref}","_^","q","\\textrm{ref}","2","_","c","\\textrm{ref}","_","S","\\textrm{ref}"]],","]]]
  ]
].freeze

RSpec.describe Latexmath::Aggregator do
  AGGREGATOR_PARAMS.each do |param|
    it (param[0]).to_s do
      tokens = Latexmath::Tokenizer.new(param[1]).tokenize
      expect(Latexmath::Aggregator.new(tokens).aggregate).to eq(param[2])
    end
  end
end
