TOKENIZER_PARAMS = [
  ['single backslash', '\\', ['\\']],
  ['alphabets', 'abcdef', 'abcdef'.chars.to_a],
  ['numbers', '445454', ['445454']],
  ['backslash after number', '123\\', ['123', '\\']],
  ['double backslash after number', '123\\\\', ['123', '\\\\']],
  ['decimal', '12.56', ['12.56']],
  ['incomplete decimal', '12.\\', ['12', '.', '\\']],
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
  ['null delimiter #1', '\\left\\{\\right.', ['\\left', '\\{', '\\right', '.']],
  [
    'matrix',
    '\\begin{matrix}a & b \\\\ c & d \\end{matrix}',
    ['\\begin{matrix}', 'a', '&', 'b', '\\\\', 'c', '&', 'd', '\\end{matrix}']
  ],
  [
    'matrix with alignment',
    '\\begin{matrix*}[r]a & b \\\\ c & d \\end{matrix*}',
    [
      '\\begin{matrix*}',
      '[',
      'r',
      ']',
      'a',
      '&',
      'b',
      '\\\\',
      'c',
      '&',
      'd',
      '\\end{matrix*}'
    ]
  ],
  [
    'matrix with negative sign',
    '\\begin{matrix}-a & b \\\\ c & d \\end{matrix}',
    ['\\begin{matrix}', '-', 'a', '&', 'b', '\\\\', 'c', '&', 'd', '\\end{matrix}']
  ],
  [
    'simple array',
    '\\begin{array}{cc} 1 & 2 \\\\ 3 & 4 \\end{array}',
    [
      '\\begin{array}',
      '{',
      'c',
      'c',
      '}',
      '1',
      '&',
      '2',
      '\\\\',
      '3',
      '&',
      '4',
      '\\end{array}'
    ]
  ],
  ['subscript', 'a_{2,n}', ['a', '_', '{', '2', ',', 'n', '}']],
  [
    'superscript with curly braces',
    'a^{i+1}_3',
    ['a', '^', '{', 'i', '+', '1', '}', '_', '3']
  ],
  [
    'issue #33',
    ''"\\begin{bmatrix}
  a_{1,1} & a_{1,2} & \\cdots & a_{1,n} \\\\
  a_{2,1} & a_{2,2} & \\cdots & a_{2,n} \\\\
  \\vdots  & \\vdots  & \\ddots & \\vdots  \\\\
  a_{m,1} & a_{m,2} & \\cdots & a_{m,n}
  \\end{bmatrix}"'',
    [
      '\\begin{bmatrix}',
      'a',
      '_',
      '{',
      '1',
      ',',
      '1',
      '}',
      '&',
      'a',
      '_',
      '{',
      '1',
      ',',
      '2',
      '}',
      '&',
      '\\cdots',
      '&',
      'a',
      '_',
      '{',
      '1',
      ',',
      'n',
      '}',
      '\\\\',
      'a',
      '_',
      '{',
      '2',
      ',',
      '1',
      '}',
      '&',
      'a',
      '_',
      '{',
      '2',
      ',',
      '2',
      '}',
      '&',
      '\\cdots',
      '&',
      'a',
      '_',
      '{',
      '2',
      ',',
      'n',
      '}',
      '\\\\',
      '\\vdots',
      '&',
      '\\vdots',
      '&',
      '\\ddots',
      '&',
      '\\vdots',
      '\\\\',
      'a',
      '_',
      '{',
      'm',
      ',',
      '1',
      '}',
      '&',
      'a',
      '_',
      '{',
      'm',
      ',',
      '2',
      '}',
      '&',
      '\\cdots',
      '&',
      'a',
      '_',
      '{',
      'm',
      ',',
      'n',
      '}',
      '\\end{bmatrix}'
    ]
  ],
  ['issue #51', '\\mathbb{R}', ['&#x0211D;']],
  [
    'issue #55',
    '\\begin{array}{rcl}ABC&=&a\\\\A&=&abc\\end{array}',
    [
      '\\begin{array}',
      '{',
      'r',
      'c',
      'l',
      '}',
      'A',
      'B',
      'C',
      '&',
      '=',
      '&',
      'a',
      '\\\\',
      'A',
      '&',
      '=',
      '&',
      'a',
      'b',
      'c',
      '\\end{array}'
    ]
  ],
  ['issue #60', '\\mathrm{...}', ['\\mathrm', '{', '.', '.', '.', '}']],
  [
    'issue #61',
    '\\frac{x + 4}{x + \\frac{123 \\left(\\sqrt{x} + 5\\right)}{x + 4} - 8}',
    [
      '\\frac',
      '{',
      'x',
      '+',
      '4',
      '}',
      '{',
      'x',
      '+',
      '\\frac',
      '{',
      '123',
      '\\left',
      '(',
      '\\sqrt',
      '{',
      'x',
      '}',
      '+',
      '5',
      '\\right',
      ')',
      '}',
      '{',
      'x',
      '+',
      '4',
      '}',
      '-',
      '8',
      '}'
    ]
  ],
  [
    'issue #63',
    '\\sqrt {\\sqrt {\\left( x^{3}\\right) + v}}',
    [
      '\\sqrt',
      '{',
      '\\sqrt',
      '{',
      '\\left',
      '(',
      'x',
      '^',
      '{',
      '3',
      '}',
      '\\right',
      ')',
      '+',
      'v',
      '}',
      '}'
    ]
  ],
  [
    'issue #77',
    '\\left[\\begin{matrix}1 & 0 & 0 & 0\\\\0 & 1 & 0 & 0\\\\0 & 0 & 1 & 0\\\\0 & 0 & 0 & 1\\end{matrix}\\right]',
    [
      '\\left',
      '[',
      '\\begin{matrix}',
      '1',
      '&',
      '0',
      '&',
      '0',
      '&',
      '0',
      '\\\\',
      '0',
      '&',
      '1',
      '&',
      '0',
      '&',
      '0',
      '\\\\',
      '0',
      '&',
      '0',
      '&',
      '1',
      '&',
      '0',
      '\\\\',
      '0',
      '&',
      '0',
      '&',
      '0',
      '&',
      '1',
      '\\end{matrix}',
      '\\right',
      ']'
    ]
  ],
  [
    'issue #78',
    'x^{x^{x^{x}}} '\
    '\\left(x^{x^{x}} \\left(x^{x} \\left(\\log{\\left(x \\right)} + 1\\right) \\log{\\left(x \\right)} + '\
    '\\frac{x^{x}}{x}\\right) \\log{\\left(x \\right)} + \\frac{x^{x^{x}}}{x}\\right)',
    [
      'x',
      '^',
      '{',
      'x',
      '^',
      '{',
      'x',
      '^',
      '{',
      'x',
      '}',
      '}',
      '}',
      '\\left',
      '(',
      'x',
      '^',
      '{',
      'x',
      '^',
      '{',
      'x',
      '}',
      '}',
      '\\left',
      '(',
      'x',
      '^',
      '{',
      'x',
      '}',
      '\\left',
      '(',
      '\\log',
      '{',
      '\\left',
      '(',
      'x',
      '\\right',
      ')',
      '}',
      '+',
      '1',
      '\\right',
      ')',
      '\\log',
      '{',
      '\\left',
      '(',
      'x',
      '\\right',
      ')',
      '}',
      '+',
      '\\frac',
      '{',
      'x',
      '^',
      '{',
      'x',
      '}',
      '}',
      '{',
      'x',
      '}',
      '\\right',
      ')',
      '\\log',
      '{',
      '\\left',
      '(',
      'x',
      '\\right',
      ')',
      '}',
      '+',
      '\\frac',
      '{',
      'x',
      '^',
      '{',
      'x',
      '^',
      '{',
      'x',
      '}',
      '}',
      '}',
      '{',
      'x',
      '}',
      '\\right',
      ')'
    ]
  ],
  [
    'max',
    '\\max_{x \\in \\[a,b\\]}f(x)',
    [
      '\\max',
      '_',
      '{',
      'x',
      '\\in',
      '\\[',
      'a',
      ',',
      'b',
      '\\]',
      '}',
      'f',
      '(',
      'x',
      ')'
    ]
  ],
  [
    'multi-line #4',
    "c_l = {L' \\over {1\\over2} \\rho_\\textrm{ref} q_\\textrm{ref}^2 c_\\textrm{ref}} \\qquad
    c_d = {D' \\over {1\\over2} \\rho_\\textrm{ref} q_\\textrm{ref}^2 c_\\textrm{ref}} \\qquad
    \\vec{c}_m = {\\vec{M}' \\over {1\\over2} \\rho_\\textrm{ref} q_\\textrm{ref}^2 c_\\textrm{ref}^2},",
    [
      'c', '_', 'l', '=',
      '{',
      'L', "'",
      '\\over',
      '{', '1', '\\over', '2', '}',
      '\\rho', '_', '\\textrm{ref}', 'q', '_', '\\textrm{ref}', '^', '2', 'c', '_', '\\textrm{ref}', '}',
      '\\qquad',

      'c', '_', 'd', '=',
      '{', 'D', "'",
      '\\over',
      '{', '1', '\\over', '2', '}',
      '\\rho', '_', '\\textrm{ref}', 'q', '_', '\\textrm{ref}', '^', '2', 'c', '_', '\\textrm{ref}', '}',
      '\\qquad',

      '\\vec{c}', '_', 'm', '=',
      '{', '\\vec{M}', "'",
      '\\over',
      '{', '1', '\\over', '2', '}',
      '\\rho', '_', '\\textrm{ref}', 'q', '_', '\\textrm{ref}', '^', '2', 'c', '_', '\\textrm{ref}', '^', '2', '}', ','
    ]
  ],
  [
    'split #1',
    "\\begin{split}
    C_L &= {L \\over {1\\over2} \\rho_\\textrm{ref} q_\\textrm{ref}^2 S} \\\\ \\\\
    C_D &= {D \\over {1\\over2} \\rho_\\textrm{ref} q_\\textrm{ref}^2 S} \\\\ \\\\
    \\vec{C}_M &= {\\vec{M} \\over {1\\over2} \\rho_\\textrm{ref} q_\\textrm{ref}^2 c_\\textrm{ref} S_\\textrm{ref}},
    \\end{split}",
    [
      '\\begin{split}',
      'C', '_', 'L', '&', '=', '{', 'L', '\\over', '{', '1', '\\over', '2', '}', '\\rho', '_', '\\textrm{ref}', 'q', '_', '\\textrm{ref}', '^', '2', 'S', '}', '\\\\', '\\\\',
      'C', '_', 'D', '&', '=', '{', 'D', '\\over', '{', '1', '\\over', '2', '}', '\\rho', '_', '\\textrm{ref}', 'q', '_', '\\textrm{ref}', '^', '2', 'S', '}', '\\\\', '\\\\',
      '\\vec{C}', '_', 'M', '&', '=', '{', '\\vec{M}', '\\over', '{', '1', '\\over', '2', '}', '\\rho', '_', '\\textrm{ref}', 'q', '_', '\\textrm{ref}', '^', '2', 'c', '_', '\\textrm{ref}', 'S', '_', '\\textrm{ref}', '}', ',',
      '\\end{split}'
    ]
  ],
  [
    'array #3',
    '\[  \left(
      \begin{array}{cccccc}
      d_{1111} & d_{1122} & d_{1133} & d_{1112} & d_{1123} & d_{1131} \\
               & d_{2222} & d_{2233} & d_{2212} & d_{2223} & d_{2231} \\
               &          & d_{3333} & d_{3312} & d_{3323} & d_{3331} \\
               &          &          & d_{1212} & d_{1223} & d_{1231} \\
               & \mbox{symmetric} & & & d_{2323} & d_{2331} \\
               &          &          &          &          & d_{3131}
      \end{array}
      \right) \]',
      ["\\[","\\left","(","\\begin{array}","{","c","c","c","c","c","c","}","d","_","{","1111","}","&","d","_","{","1122","}","&","d","_","{","1133","}","&","d","_","{","1112","}","&","d","_","{","1123","}","&","d","_","{","1131","}","\\","&","d","_","{","2222","}","&","d","_","{","2233","}","&","d","_","{","2212","}","&","d","_","{","2223","}","&","d","_","{","2231","}","\\","&","&","d","_","{","3333","}","&","d","_","{","3312","}","&","d","_","{","3323","}","&","d","_","{","3331","}","\\","&","&","&","d","_","{","1212","}","&","d","_","{","1223","}","&","d","_","{","1231","}","\\","&","\\mbox{symmetric}","&","&","&","d","_","{","2323","}","&","d","_","{","2331","}","\\","&","&","&","&","&","d","_","{","3131","}","\\end{array}","\\right",")","\\]"]
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
    ["\\begin{array}","{","c","c","}",
      "\\left","(",
        "\\begin{array}","{","c","c","c","c","c","c","c","}",
          "&","&","&","&","&","&","\\\\",
          "&","+","k","&","&","&","&","-","k","\\\\",
          "&","&","&","&","&","&","\\\\",
          "&","&","&","&","&","&","\\\\",
          "&","&","&","&","&","&","\\\\",
          "&","-","k","&","&","&","&","+","k",
        "\\end{array}",
      "\\right",")",
      "&",
      "\\begin{array}","{","c","c","}",
        "&","\\\\","\\cdots","&","\\mbox{degree of freedom 1, node 1}","\\\\",
        "&","\\\\",
        "&","\\\\",
        "&","\\\\",
        "\\cdots","&","\\mbox{degree of freedom 2, node 2}",
      "\\end{array}", "\\\\",
      "&","\\\\",
      "\\begin{array}","{","c","c","c","c","c","c","}",
        "\\vdots","&","&","&","&","&","\\vdots",
      "\\end{array}","&","\\\\",
      "\\begin{array}","{","c","c","c","c","}",
        "&","\\mbox{degree of}","&","\\mbox{degree of}","&","\\\\",
        "&","\\mbox{freedom 1,}","&","\\mbox{freedom 2,}","&","\\\\","&","\\mbox{node 1}","&","\\mbox{node 2}","&","\\end{array}","&","\\end{array}"]
  ]
].freeze

RSpec.describe Latexmath::Tokenizer do
  it 'has a version number' do
    expect(Latexmath::VERSION).not_to be nil
  end

  TOKENIZER_PARAMS.each do |param|
    it (param[0]).to_s do
      expect(Latexmath::Tokenizer.new(param[1]).tokenize).to eq(param[2])
    end
  end
end
