RSpec.describe Latexmath::Core::Mouth do

  context 'Sample 1' do
    tex = '\\varepsilon = \\frac{1}{2} ( J + J^t )'
    it 'Tokenize latex string' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:to_s)
      ).to eq(
        ['\\varepsilon', '=', ' ', '\\frac', '{', '1', '}', '{', '2', '}', ' ', '(', ' ', 'J', ' ', '+', ' ', 'J', '^', 't', ' ', ')']
      )
    end

    it 'Tokenize latex codes' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:catcode)
      ).to eq(
        [16, 12, 10, 16, 1, 12, 2, 1, 12, 2, 10, 12, 10, 11, 10, 12, 10, 11, 7, 11, 10, 12]
      )
    end
  end

  context 'Sample 2' do
    tex = '$$f_i =  \\sum_{j=1}^2 s_{ij} n_j \\quad {\\rm for} \\quad i = 1,2$$'
    it 'Tokenize latex string' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:to_s)
      ).to eq(
        ['$', '$', 'f', '_', 'i', ' ', '=', ' ', '\\sum', '_', '{', 'j', '=', '1', '}', '^', '2', ' ', 's', '_', '{', 'i', 'j', '}', ' ', 'n', '_', 'j', ' ', '\\quad', '{', '\\rm', 'f', 'o', 'r', '}', ' ', '\\quad', 'i', ' ', '=', ' ', '1', ',', '2', '$', '$']
      )
    end

    it 'Tokenize latex codes' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:catcode)
      ).to eq(
        [3, 3, 11, 8, 11, 10, 12, 10, 16, 8, 1, 11, 12, 12, 2, 7, 12, 10, 11, 8, 1, 11, 11, 2,
         10, 11, 8, 11, 10, 16, 1, 16, 11, 11, 11, 2, 10, 16, 11, 10, 12, 10, 12, 12, 12, 3, 3]
      )
    end
  end

  context 'Sample 3' do
    tex = 'G = {\\displaystyle \\frac{E}{2(1 + \\nu)}}'
    it 'Tokenize latex string' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:to_s)
      ).to eq(
        ['G', ' ', '=', ' ', '{', '\\displaystyle', '\\frac', '{', 'E', '}', '{', '2', '(', '1', ' ', '+', ' ', '\\nu', ')', '}', '}']
      )
    end

    it 'Tokenize latex codes' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:catcode)
      ).to eq(
        [11, 10, 12, 10, 1, 16, 16, 1, 11, 2, 1, 12, 12, 12, 10, 12, 10, 16, 12, 2, 2]
      )
    end
  end

  context 'Sample 4' do
    tex = '\\bf{x^\\prime} = \\bf{\\xi}'

    it 'Tokenize latex string' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:to_s)
      ).to eq(
        ["\\bf", "{", "x", "^", "\\prime", "}", " ", "=", " ", "\\bf", "{", "\\xi", "}"]
      )
    end

    it 'Tokenize latex codes' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:catcode)
      ).to eq(
        [16,1,11,7,16,2,10,12,10,16,1,16,2]
      )
    end
  end

  context 'Sample 5' do
    tex = '\\bf{z^\\prime} = \\langle \\bf{\\xi} \\times \\bf{\\eta} \\rangle'

    it 'Tokenize latex string' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:to_s)
      ).to eq(
        ["\\bf", "{", "z", "^", "\\prime", "}", " ", "=", " ", "\\langle", "\\bf", "{", "\\xi", "}", " ", "\\times", "\\bf", "{", "\\eta", "}", " ","\\rangle"]
      )
    end

    it 'Tokenize latex codes' do
      expect(
        Latexmath::Core::Mouth.new(tex).read_tokens.to_a.map(&:catcode)
      ).to eq(
        [16,1,11,7,16,2,10,12,10,16,16,1,16,2,10,16,16,1,16,2,10,16]
      )
    end
  end
end
