require 'strscan'

module Latexmath
  class Tokenizer < StringScanner
    def tokenize
      exp = []

      while token = fetch_token
        exp << token
      end

      exp
    end

    def fetch_token
      skip(/\s+/)
      skip(/\$\$/)

      token = if scan(/\\mathbb\{[^}]+}/)
                if Latexmath::Symbol.get(matched)
                  "&#x#{Latexmath::Symbol.get(matched)};"
                else
                  matched
                end
              elsif scan(/{\\bf [^}]+}/)
                matches = matched.match(/{\\bf ([^}]+)}/)
                symbol = "\\mathbf{#{matches[1]}}"
                if Latexmath::Symbol.get(symbol)
                  "&#x#{Latexmath::Symbol.get(symbol)};"
                end
              elsif scan(/\\\\\[\d+mm\]/)
                '\\\\' # matched
              elsif scan(/\\mbox{[^\}]+}/)
                matched
              elsif scan(/\\vec{[^\}]+}/)
                matched
              elsif scan(/\\hat{[^\}]+}/)
                matched
              elsif scan(/\\textrm{[^\}]+}/)
                matched
              elsif scan(/{\\rm [^}]+}/)
                matches = matched.match(/{\\rm ([^}]+)}/)
                matches[1]
              elsif scan(/\\[a-z]+\{(bmatrix|Bmatrix|matrix|vmatrix|Vmatrix|array|pmatrix|split)\*?\}/)
                matched
              elsif scan(/\\[a-z]+/)
                matched
              elsif scan(/\\\\/)
                matched
              elsif scan(/\\\[/)
                matched
              elsif scan(/\\\]/)
                matched
              elsif scan(/\\\{/)
                matched
              elsif scan(/\\,/)
                matched
              elsif scan(/\\:/)
                matched
              elsif scan(/\\/)
                matched
              elsif scan(/[a-z]/)
                matched
              elsif scan(/[0-9]+\.[0-9]+/)
                matched
              elsif scan(/[0-9]+/)
                matched
              elsif scan(/ /)
                matched
              elsif scan(/[\{\}\*]/)
                matched
              elsif scan(/./)
                matched
              end

      token
    end
  end
end
