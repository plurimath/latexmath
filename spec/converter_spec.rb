PARAMS = [
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
  # (
  #     "complex matrix",
  #     r"\begin{matrix}a_{1} & b_{2} \\ c_{3} & d_{4} \end{matrix}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             (
  #                                 "mtd",
  #                                 {
  #                                     "msub": MultiDict(
  #                                         [("mi", "a"), ("mrow", {"mn": "1"})]
  #                                     )
  #                                 },
  #                             ),
  #                             (
  #                                 "mtd",
  #                                 {
  #                                     "msub": MultiDict(
  #                                         [("mi", "b"), ("mrow", {"mn": "2"})]
  #                                     )
  #                                 },
  #                             ),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             (
  #                                 "mtd",
  #                                 {
  #                                     "msub": MultiDict(
  #                                         [("mi", "c"), ("mrow", {"mn": "3"})]
  #                                     )
  #                                 },
  #                             ),
  #                             (
  #                                 "mtd",
  #                                 {
  #                                     "msub": MultiDict(
  #                                         [("mi", "d"), ("mrow", {"mn": "4"})]
  #                                     )
  #                                 },
  #                             ),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
  # (
  #     "null delimiter",
  #     r"\left\{ \begin{array} { l } { 3x - 5y + 4z = 0} \\ { x - y + 8z = 0} \\ { 2x - 6y + z = 0} \end{array} "
  #     r"\right.",
  #     {
  #         "mrow": MultiDict(
  #             [
  #                 (
  #                     "mo",
  #                     MultiDict(
  #                         [
  #                             ("@stretchy", "true"),
  #                             ("@fence", "true"),
  #                             ("@form", "prefix"),
  #                             ("$", "&#x0007B;"),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mrow",
  #                     {
  #                         "mtable": MultiDict(
  #                             [
  #                                 (
  #                                     "mtr",
  #                                     MultiDict(
  #                                         [
  #                                             (
  #                                                 "mtd",
  #                                                 MultiDict(
  #                                                     [
  #                                                         ("@columnalign", "left"),
  #                                                         ("mn", "3"),
  #                                                         ("mi", "x"),
  #                                                         ("mo", "&#x02212;"),
  #                                                         ("mn", "5"),
  #                                                         ("mi", "y"),
  #                                                         ("mo", "&#x0002B;"),
  #                                                         ("mn", "4"),
  #                                                         ("mi", "z"),
  #                                                         ("mo", "&#x0003D;"),
  #                                                         ("mn", "0"),
  #                                                     ]
  #                                                 ),
  #                                             ),
  #                                         ]
  #                                     ),
  #                                 ),
  #                                 (
  #                                     "mtr",
  #                                     MultiDict(
  #                                         [
  #                                             (
  #                                                 "mtd",
  #                                                 MultiDict(
  #                                                     [
  #                                                         ("@columnalign", "left"),
  #                                                         ("mi", "x"),
  #                                                         ("mo", "&#x02212;"),
  #                                                         ("mi", "y"),
  #                                                         ("mo", "&#x0002B;"),
  #                                                         ("mn", "8"),
  #                                                         ("mi", "z"),
  #                                                         ("mo", "&#x0003D;"),
  #                                                         ("mn", "0"),
  #                                                     ]
  #                                                 ),
  #                                             ),
  #                                         ]
  #                                     ),
  #                                 ),
  #                                 (
  #                                     "mtr",
  #                                     MultiDict(
  #                                         [
  #                                             (
  #                                                 "mtd",
  #                                                 MultiDict(
  #                                                     [
  #                                                         ("@columnalign", "left"),
  #                                                         ("mn", "2"),
  #                                                         ("mi", "x"),
  #                                                         ("mo", "&#x02212;"),
  #                                                         ("mn", "6"),
  #                                                         ("mi", "y"),
  #                                                         ("mo", "&#x0002B;"),
  #                                                         ("mi", "z"),
  #                                                         ("mo", "&#x0003D;"),
  #                                                         ("mn", "0"),
  #                                                     ]
  #                                                 ),
  #                                             ),
  #                                         ]
  #                                     ),
  #                                 ),
  #                             ]
  #                         )
  #                     },
  #                 ),
  #                 (
  #                     "mo",
  #                     MultiDict(
  #                         [
  #                             ("@stretchy", "true"),
  #                             ("@fence", "true"),
  #                             ("@form", "postfix"),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
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
    '<msubsup><mi>a</mi><mi>c/mi><mi>b</mi></msubsup>'
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
  # (
  #     "superscript, subscript and curly braces",
  #     "a^{i+1}_3",
  #     {
  #         "msubsup": MultiDict(
  #             [
  #                 ("mi", "a"),
  #                 ("mn", "3"),
  #                 (
  #                     "mrow",
  #                     MultiDict([("mi", "i"), ("mo", "&#x0002B;"), ("mn", "1")]),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
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
  # (
  #     "binomial",
  #     r"\binom{2}{3}",
  #     MultiDict(
  #         [
  #             ("mo", "&#x00028;"),
  #             (
  #                 "mfrac",
  #                 MultiDict(
  #                     [
  #                         ("@linethickness", "0"),
  #                         ("mrow", {"mn": "2"}),
  #                         ("mrow", {"mn": "3"}),
  #                     ]
  #                 ),
  #             ),
  #             ("mo", "&#x00029;"),
  #         ]
  #     ),
  # ),
  # (
  #     "left and right",
  #     r"\left(x\right)",
  #     MultiDict(
  #         [
  #             (
  #                 "mrow",
  #                 MultiDict(
  #                     [
  #                         (
  #                             "mo",
  #                             MultiDict(
  #                                 [
  #                                     ("@stretchy", "true"),
  #                                     ("@fence", "true"),
  #                                     ("@form", "prefix"),
  #                                     ("$", "&#x00028;"),
  #                                 ]
  #                             ),
  #                         ),
  #                         ("mrow", {"mi": "x"}),
  #                         (
  #                             "mo",
  #                             MultiDict(
  #                                 [
  #                                     ("@stretchy", "true"),
  #                                     ("@fence", "true"),
  #                                     ("@form", "postfix"),
  #                                     ("$", "&#x00029;"),
  #                                 ]
  #                             ),
  #                         ),
  #                     ]
  #                 ),
  #             ),
  #         ]
  #     ),
  # ),
  ['space', '\\,', '<mspace width="0.167em" />'],
  [
    'overline',
    '\\overline{a}',
    '<mover><mrow><mi>a</mi></mrow><mo stretchy="true">&#x000AF;</mo></mover>'
  ],
  # (
  #     "underline",
  #     r"\underline{a}",
  #     {
  #         "munder": MultiDict(
  #             [("mrow", {"mi": "a"}), ("mo", {"@stretchy": "true", "$": "&#x00332;"})]
  #         )
  #     },
  # ),
  # (
  #     "matrix",
  #     r"\begin{matrix}a & b \\ c & d \end{matrix}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 ("mtr", MultiDict([("mtd", {"mi": "a"}), ("mtd", {"mi": "b"})]),),
  #                 ("mtr", MultiDict([("mtd", {"mi": "c"}), ("mtd", {"mi": "d"})]),),
  #             ]
  #         ),
  #     },
  # ),
  # (
  #     "matrix without begin and end",
  #     r"\matrix{a & b \\ c & d}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 ("mtr", MultiDict([("mtd", {"mi": "a"}), ("mtd", {"mi": "b"})]),),
  #                 ("mtr", MultiDict([("mtd", {"mi": "c"}), ("mtd", {"mi": "d"})]),),
  #             ]
  #         ),
  #     },
  # ),
  # (
  #     "matrix with alignment",
  #     r"\begin{matrix*}[r]a & b \\ c & d \end{matrix*}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "right", "mi": "a"}),
  #                             ("mtd", {"@columnalign": "right", "mi": "b"}),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "right", "mi": "c"}),
  #                             ("mtd", {"@columnalign": "right", "mi": "d"}),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
  # (
  #     "matrix with negative sign",
  #     r"\begin{matrix}-a & b \\ c & d \end{matrix}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", MultiDict([("mo", "&#x02212;"), ("mi", "a")])),
  #                             ("mtd", {"mi": "b"}),
  #                         ]
  #                     ),
  #                 ),
  #                 ("mtr", MultiDict([("mtd", {"mi": "c"}), ("mtd", {"mi": "d"})]),),
  #             ]
  #         ),
  #     },
  # ),
  # (
  #     "pmatrix",
  #     r"\begin{pmatrix}a & b \\ c & d \end{pmatrix}",
  #     MultiDict(
  #         [
  #             ("mo", "&#x00028;"),
  #             (
  #                 "mtable",
  #                 MultiDict(
  #                     [
  #                         (
  #                             "mtr",
  #                             MultiDict([("mtd", {"mi": "a"}), ("mtd", {"mi": "b"})]),
  #                         ),
  #                         (
  #                             "mtr",
  #                             MultiDict([("mtd", {"mi": "c"}), ("mtd", {"mi": "d"})]),
  #                         ),
  #                     ]
  #                 ),
  #             ),
  #             ("mo", "&#x00029;"),
  #         ]
  #     ),
  # ),
  # (
  #     "simple array",
  #     r"\begin{array}{cr} 1 & 2 \\ 3 & 4 \end{array}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "center", "mn": "1"}),
  #                             ("mtd", {"@columnalign": "right", "mn": "2"}),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "center", "mn": "3"}),
  #                             ("mtd", {"@columnalign": "right", "mn": "4"}),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
  # (
  #     "array with vertical bar",
  #     r"\begin{array}{c|rl} 1 & 2 & 3 \\ 4 & 5 & 6 \end{array}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 ("@columnlines", "solid none"),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "center", "mn": "1"}),
  #                             ("mtd", {"@columnalign": "right", "mn": "2"}),
  #                             ("mtd", {"@columnalign": "left", "mn": "3"}),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "center", "mn": "4"}),
  #                             ("mtd", {"@columnalign": "right", "mn": "5"}),
  #                             ("mtd", {"@columnalign": "left", "mn": "6"}),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
  # (
  #     "array with horizontal lines",
  #     r"\begin{array}{cr} 1 & 2 \\ 3 & 4 \\ \hline 5 & 6 \end{array}",
  #     {
  #         "mtable": MultiDict(
  #             [
  #                 ("@rowlines", "none solid"),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "center", "mn": "1"}),
  #                             ("mtd", {"@columnalign": "right", "mn": "2"}),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "center", "mn": "3"}),
  #                             ("mtd", {"@columnalign": "right", "mn": "4"}),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mtr",
  #                     MultiDict(
  #                         [
  #                             ("mtd", {"@columnalign": "center", "mn": "5"}),
  #                             ("mtd", {"@columnalign": "right", "mn": "6"}),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
  # (
  #     "issue #33",
  #     r"""\begin{bmatrix}
  #  a_{1,1} & a_{1,2} & \cdots & a_{1,n} \\
  #  a_{2,1} & a_{2,2} & \cdots & a_{2,n} \\
  #  \vdots  & \vdots  & \ddots & \vdots  \\
  #  a_{m,1} & a_{m,2} & \cdots & a_{m,n}
  # \end{bmatrix}""",
  #     MultiDict(
  #         [
  #             ("mo", "&#x0005B;"),
  #             (
  #                 "mtable",
  #                 MultiDict(
  #                     [
  #                         (
  #                             "mtr",
  #                             MultiDict(
  #                                 [
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mn", "1"),
  #                                                                 ("mi", ","),
  #                                                                 ("mn", "1"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mn", "1"),
  #                                                                 ("mi", ","),
  #                                                                 ("mn", "2"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                     ("mtd", {"mo": "&#x022EF;"}),
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mn", "1"),
  #                                                                 ("mi", ","),
  #                                                                 ("mi", "n"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                 ]
  #                             ),
  #                         ),
  #                         (
  #                             "mtr",
  #                             MultiDict(
  #                                 [
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mn", "2"),
  #                                                                 ("mi", ","),
  #                                                                 ("mn", "1"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mn", "2"),
  #                                                                 ("mi", ","),
  #                                                                 ("mn", "2"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                     ("mtd", {"mo": "&#x022EF;"}),
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mn", "2"),
  #                                                                 ("mi", ","),
  #                                                                 ("mi", "n"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                 ]
  #                             ),
  #                         ),
  #                         (
  #                             "mtr",
  #                             MultiDict(
  #                                 [
  #                                     ("mtd", {"mo": "&#x022EE;"}),
  #                                     ("mtd", {"mo": "&#x022EE;"}),
  #                                     ("mtd", {"mo": "&#x022F1;"}),
  #                                     ("mtd", {"mo": "&#x022EE;"}),
  #                                 ]
  #                             ),
  #                         ),
  #                         (
  #                             "mtr",
  #                             MultiDict(
  #                                 [
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mi", "m"),
  #                                                                 ("mi", ","),
  #                                                                 ("mn", "1"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mi", "m"),
  #                                                                 ("mi", ","),
  #                                                                 ("mn", "2"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                     ("mtd", {"mo": "&#x022EF;"}),
  #                                     (
  #                                         "mtd",
  #                                         {
  #                                             "msub": MultiDict(
  #                                                 [
  #                                                     ("mi", "a"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 ("mi", "m"),
  #                                                                 ("mi", ","),
  #                                                                 ("mi", "n"),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                 ]
  #                             ),
  #                         ),
  #                     ]
  #                 ),
  #             ),
  #             ("mo", "&#x0005D;"),
  #         ]
  #     ),
  # ),
  # (
  #     "issue #42",
  #     r"\sqrt { ( - 25 ) ^ { 2 } } = \pm 25",
  #     MultiDict(
  #         [
  #             (
  #                 "msqrt",
  #                 {
  #                     "mrow": MultiDict(
  #                         [
  #                             (
  #                                 "msup",
  #                                 MultiDict(
  #                                     [
  #                                         (
  #                                             "mrow",
  #                                             MultiDict(
  #                                                 [
  #                                                     (
  #                                                         "mo",
  #                                                         {
  #                                                             "$": "&#x00028;",
  #                                                             "@stretchy": "false",
  #                                                         },
  #                                                     ),
  #                                                     ("mo", {"$": "&#x02212;"}),
  #                                                     ("mn", {"$": "25"}),
  #                                                     (
  #                                                         "mo",
  #                                                         {
  #                                                             "$": "&#x00029;",
  #                                                             "@stretchy": "false",
  #                                                         },
  #                                                     ),
  #                                                 ]
  #                                             ),
  #                                         ),
  #                                         ("mrow", {"mn": {"$": "2"}}),
  #                                     ]
  #                                 ),
  #                             ),
  #                         ]
  #                     )
  #                 },
  #             ),
  #             ("mo", {"$": "&#x0003D;"}),
  #             ("mi", {"$": "&#x000B1;"}),
  #             ("mn", {"$": "25"}),
  #         ]
  #     ),
  # ),
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
  # (
  #     "issue #44",
  #     r"\left(- x^{3} + 5\right)^{5}",
  #     MultiDict(
  #         [
  #             (
  #                 "msup",
  #                 MultiDict(
  #                     [
  #                         (
  #                             "mrow",
  #                             MultiDict(
  #                                 [
  #                                     (
  #                                         "mo",
  #                                         MultiDict(
  #                                             [
  #                                                 ("@stretchy", "true"),
  #                                                 ("@fence", "true"),
  #                                                 ("@form", "prefix"),
  #                                                 ("$", "&#x00028;"),
  #                                             ]
  #                                         ),
  #                                     ),
  #                                     (
  #                                         "mrow",
  #                                         MultiDict(
  #                                             [
  #                                                 ("mo", "&#x02212;"),
  #                                                 (
  #                                                     "msup",
  #                                                     MultiDict(
  #                                                         [
  #                                                             ("mi", "x"),
  #                                                             ("mrow", {"mn": "3"},),
  #                                                         ]
  #                                                     ),
  #                                                 ),
  #                                                 ("mo", "&#x0002B;"),
  #                                                 ("mn", "5"),
  #                                             ]
  #                                         ),
  #                                     ),
  #                                     (
  #                                         "mo",
  #                                         MultiDict(
  #                                             [
  #                                                 ("@stretchy", "true"),
  #                                                 ("@fence", "true"),
  #                                                 ("@form", "postfix"),
  #                                                 ("$", "&#x00029;"),
  #                                             ]
  #                                         ),
  #                                     ),
  #                                 ]
  #                             ),
  #                         ),
  #                         ("mrow", {"mn": "5"}),
  #                     ]
  #                 ),
  #             )
  #         ]
  #     ),
  # ),
  # ("issue #51", r"\mathbb{R}", {"mi": "&#x0211D;"}),
  # (
  #     "issue #60-1",
  #     r"\mathrm{...}",
  #     {"mrow": MultiDict([("mo", "."), ("mo", "."), ("mo", ".")])},
  # ),
  # (
  #     "issue #52",
  #     r"\bar{z_1} = z_2",
  #     MultiDict(
  #         [
  #             (
  #                 "mover",
  #                 MultiDict(
  #                     [
  #                         ("mrow", {"msub": MultiDict([("mi", "z"), ("mn", "1")])}),
  #                         ("mo", {"@stretchy": "true", "$": "&#x000AF;"}),
  #                     ]
  #                 ),
  #             ),
  #             ("mo", "&#x0003D;"),
  #             ("msub", MultiDict([("mi", "z"), ("mn", "2")])),
  #         ]
  #     ),
  # ),
  # (
  #     "issue #60-2",
  #     r"\mathrm{...}+\mathrm{...}",
  #     MultiDict(
  #         [
  #             ("mrow", MultiDict([("mo", "."), ("mo", "."), ("mo", ".")])),
  #             ("mo", "&#x0002B;"),
  #             ("mrow", MultiDict([("mo", "."), ("mo", "."), ("mo", ".")])),
  #         ]
  #     ),
  # ),
  # (
  #     "issue #61",
  #     r"\frac{x + 4}{x + \frac{123 \left(\sqrt{x} + 5\right)}{x + 4} - 8}",
  #     {
  #         "mfrac": MultiDict(
  #             [
  #                 (
  #                     "mrow",
  #                     MultiDict([("mi", "x"), ("mo", "&#x0002B;"), ("mn", "4")]),
  #                 ),
  #                 (
  #                     "mrow",
  #                     MultiDict(
  #                         [
  #                             ("mi", "x"),
  #                             ("mo", "&#x0002B;"),
  #                             (
  #                                 "mfrac",
  #                                 MultiDict(
  #                                     [
  #                                         (
  #                                             "mrow",
  #                                             MultiDict(
  #                                                 [
  #                                                     ("mn", "123"),
  #                                                     (
  #                                                         "mrow",
  #                                                         MultiDict(
  #                                                             [
  #                                                                 (
  #                                                                     "mo",
  #                                                                     MultiDict(
  #                                                                         [
  #                                                                             (
  #                                                                                 "@stretchy",
  #                                                                                 "true",
  #                                                                             ),
  #                                                                             (
  #                                                                                 "@fence",
  #                                                                                 "true",
  #                                                                             ),
  #                                                                             (
  #                                                                                 "@form",
  #                                                                                 "prefix",
  #                                                                             ),
  #                                                                             (
  #                                                                                 "$",
  #                                                                                 "&#x00028;",
  #                                                                             ),
  #                                                                         ]
  #                                                                     ),
  #                                                                 ),
  #                                                                 (
  #                                                                     "mrow",
  #                                                                     MultiDict(
  #                                                                         [
  #                                                                             (
  #                                                                                 "msqrt",
  #                                                                                 {
  #                                                                                     "mrow": {
  #                                                                                         "mi": "x"
  #                                                                                     }
  #                                                                                 },
  #                                                                             ),
  #                                                                             (
  #                                                                                 "mo",
  #                                                                                 "&#x0002B;",
  #                                                                             ),
  #                                                                             (
  #                                                                                 "mn",
  #                                                                                 "5",
  #                                                                             ),
  #                                                                         ]
  #                                                                     ),
  #                                                                 ),
  #                                                                 (
  #                                                                     "mo",
  #                                                                     MultiDict(
  #                                                                         [
  #                                                                             (
  #                                                                                 "@stretchy",
  #                                                                                 "true",
  #                                                                             ),
  #                                                                             (
  #                                                                                 "@fence",
  #                                                                                 "true",
  #                                                                             ),
  #                                                                             (
  #                                                                                 "@form",
  #                                                                                 "postfix",
  #                                                                             ),
  #                                                                             (
  #                                                                                 "$",
  #                                                                                 "&#x00029;",
  #                                                                             ),
  #                                                                         ]
  #                                                                     ),
  #                                                                 ),
  #                                                             ]
  #                                                         ),
  #                                                     ),
  #                                                 ]
  #                                             ),
  #                                         ),
  #                                         (
  #                                             "mrow",
  #                                             MultiDict(
  #                                                 [
  #                                                     ("mi", "x"),
  #                                                     ("mo", "&#x0002B;"),
  #                                                     ("mn", "4"),
  #                                                 ]
  #                                             ),
  #                                         ),
  #                                     ]
  #                                 ),
  #                             ),
  #                             ("mo", "&#x02212;"),
  #                             ("mn", "8"),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
  # (
  #     "issue #63",
  #     r"\sqrt {\sqrt {\left( x^{3}\right) + v}}",
  #     {
  #         "msqrt": {
  #             "mrow": {
  #                 "msqrt": {
  #                     "mrow": MultiDict(
  #                         [
  #                             (
  #                                 "mrow",
  #                                 MultiDict(
  #                                     [
  #                                         (
  #                                             "mo",
  #                                             MultiDict(
  #                                                 [
  #                                                     ("@stretchy", "true"),
  #                                                     ("@fence", "true"),
  #                                                     ("@form", "prefix"),
  #                                                     ("$", "&#x00028;"),
  #                                                 ]
  #                                             ),
  #                                         ),
  #                                         (
  #                                             "mrow",
  #                                             {
  #                                                 "msup": MultiDict(
  #                                                     [
  #                                                         ("mi", "x"),
  #                                                         ("mrow", {"mn": 3}),
  #                                                     ]
  #                                                 )
  #                                             },
  #                                         ),
  #                                         (
  #                                             "mo",
  #                                             MultiDict(
  #                                                 [
  #                                                     ("@stretchy", "true"),
  #                                                     ("@fence", "true"),
  #                                                     ("@form", "postfix"),
  #                                                     ("$", "&#x00029;"),
  #                                                 ]
  #                                             ),
  #                                         ),
  #                                     ]
  #                                 ),
  #                             ),
  #                             ("mo", "&#x0002B;"),
  #                             ("mi", "v"),
  #                         ]
  #                     ),
  #                 }
  #             }
  #         }
  #     },
  # ),
  # (r"empty subscript", r"1_{}", {"msub": MultiDict([("mn", "1"), ("mrow", {})])}),
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
  # (
  #     "issue #77",
  #     r"\left[\begin{matrix}1 & 0 & 0 & 0\\0 & 1 & 0 & 0\\0 & 0 & 1 & 0\\0 & 0 & 0 & 1\end{matrix}\right]",
  #     {
  #         "mrow": MultiDict(
  #             [
  #                 (
  #                     "mo",
  #                     MultiDict(
  #                         [
  #                             ("@stretchy", "true"),
  #                             ("@fence", "true"),
  #                             ("@form", "prefix"),
  #                             ("$", "["),
  #                         ]
  #                     ),
  #                 ),
  #                 (
  #                     "mrow",
  #                     {
  #                         "mtable": MultiDict(
  #                             [
  #                                 (
  #                                     "mtr",
  #                                     MultiDict(
  #                                         [
  #                                             ("mtd", {"mn": "1"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                         ]
  #                                     ),
  #                                 ),
  #                                 (
  #                                     "mtr",
  #                                     MultiDict(
  #                                         [
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "1"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                         ]
  #                                     ),
  #                                 ),
  #                                 (
  #                                     "mtr",
  #                                     MultiDict(
  #                                         [
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "1"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                         ]
  #                                     ),
  #                                 ),
  #                                 (
  #                                     "mtr",
  #                                     MultiDict(
  #                                         [
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "0"}),
  #                                             ("mtd", {"mn": "1"}),
  #                                         ]
  #                                     ),
  #                                 ),
  #                             ]
  #                         )
  #                     },
  #                 ),
  #                 (
  #                     "mo",
  #                     MultiDict(
  #                         [
  #                             ("@stretchy", "true"),
  #                             ("@fence", "true"),
  #                             ("@form", "postfix"),
  #                             ("$", "]"),
  #                         ]
  #                     ),
  #                 ),
  #             ]
  #         )
  #     },
  # ),
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
  # (
  #     "limit at plus infinity",
  #     r"\lim_{x \to +\infty} f(x)",
  #     MultiDict(
  #         [
  #             (
  #                 "munder",
  #                 MultiDict(
  #                     [
  #                         ("mo", "lim"),
  #                         (
  #                             "mrow",
  #                             MultiDict(
  #                                 [
  #                                     ("mi", "x"),
  #                                     ("mo", "&#x02192;"),
  #                                     ("mo", "&#x0002B;"),
  #                                     ("mo", "&#x0221E;"),
  #                                 ]
  #                             ),
  #                         ),
  #                     ]
  #                 ),
  #             ),
  #             ("mi", "f"),
  #             ("mo", {"$": "&#x00028;", "@stretchy": "false"}),
  #             ("mi", "x"),
  #             ("mo", {"$": "&#x00029;", "@stretchy": "false"}),
  #         ]
  #     ),
  # ),
  # (
  #     "inf",
  #     r"\inf_{x > s}f(x)",
  #     MultiDict(
  #         [
  #             (
  #                 "munder",
  #                 MultiDict(
  #                     [
  #                         ("mo", "inf"),
  #                         (
  #                             "mrow",
  #                             MultiDict([("mi", "x"), ("mo", "&gt;"), ("mi", "s")]),
  #                         ),
  #                     ]
  #                 ),
  #             ),
  #             ("mi", "f"),
  #             ("mo", {"$": "&#x00028;", "@stretchy": "false"}),
  #             ("mi", "x"),
  #             ("mo", {"$": "&#x00029;", "@stretchy": "false"}),
  #         ]
  #     ),
  # ),
  # (
  #     "issue #76",
  #     r"\int\limits_{0}^{\pi}",
  #     MultiDict(
  #         [
  #             (
  #                 "munderover",
  #                 MultiDict(
  #                     [
  #                         ("mo", "&#x0222B;"),
  #                         ("mrow", MultiDict([("mn", "0")])),
  #                         ("mrow", MultiDict([("mi", "&#x003C0;")])),
  #                     ]
  #                 ),
  #             ),
  #         ]
  #     ),
  # ),
  # (
  #     "issue #75 - 1 row",
  #     r"\substack{ \xi{2}=g{\left(x \right)}}",
  #     {
  #         "mstyle": {
  #             "@scriptlevel": "1",
  #             "mtable": {
  #                 "mtr": {
  #                     "mtd": MultiDict(
  #                         [
  #                             ("mi", "&#x003BE;"),
  #                             ("mn", "2"),
  #                             ("mo", "&#x0003D;"),
  #                             ("mi", "g"),
  #                             (
  #                                 "mrow",
  #                                 MultiDict(
  #                                     [
  #                                         (
  #                                             "mo",
  #                                             MultiDict(
  #                                                 [
  #                                                     ("@stretchy", "true"),
  #                                                     ("@fence", "true"),
  #                                                     ("@form", "prefix"),
  #                                                     ("$", "&#x00028;"),
  #                                                 ]
  #                                             ),
  #                                         ),
  #                                         ("mrow", {"mi": "x"}),
  #                                         (
  #                                             "mo",
  #                                             MultiDict(
  #                                                 [
  #                                                     ("@stretchy", "true"),
  #                                                     ("@fence", "true"),
  #                                                     ("@form", "postfix"),
  #                                                     ("$", "&#x00029;"),
  #                                                 ]
  #                                             ),
  #                                         ),
  #                                     ]
  #                                 ),
  #                             ),
  #                         ]
  #                     )
  #                 }
  #             },
  #         }
  #     },
  # ),
  # (
  #     "issue #75 - 2 rows",
  #     r"\sum_{\substack{1\le i\le n\\ i\ne j}}",
  #     {
  #         "munder": MultiDict(
  #             [
  #                 ("mo", "&#x02211;"),
  #                 (
  #                     "mrow",
  #                     {
  #                         "mstyle": {
  #                             "@scriptlevel": "1",
  #                             "mtable": MultiDict(
  #                                 [
  #                                     (
  #                                         "mtr",
  #                                         {
  #                                             "mtd": MultiDict(
  #                                                 [
  #                                                     ("mn", "1"),
  #                                                     ("mo", "&#x02264;"),
  #                                                     ("mi", "i"),
  #                                                     ("mo", "&#x02264;"),
  #                                                     ("mi", "n"),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                     (
  #                                         "mtr",
  #                                         {
  #                                             "mtd": MultiDict(
  #                                                 [
  #                                                     ("mi", "i"),
  #                                                     ("mo", "&#x02260;"),
  #                                                     ("mi", "j"),
  #                                                 ]
  #                                             )
  #                                         },
  #                                     ),
  #                                 ]
  #                             ),
  #                         }
  #                     },
  #                 ),
  #             ]
  #         )
  #     },
  # ),
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
  ]
].freeze

RSpec.describe Latexmath do
  PARAMS.each do |param|
    it (param[0]).to_s do
      tokens = Latexmath::Tokenizer.new(param[1]).tokenize
      aggr = Latexmath::Aggregator.new(tokens).aggregate
      expect(Latexmath::Converter.new(aggr).convert).to eq(
        Ox.dump(
          Ox.parse("
            <math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"inline\">
              <mrow>#{param[2]}</mrow>
            </math>
          ")
        )
      )
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
