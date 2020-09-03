module Latexmath
  class Converter
    def initialize(aggregate)
      @aggregate = aggregate
    end

    def convert(xmlns = 'http://www.w3.org/1998/Math/MathML', display = 'block')
      @doc = Ox::Document.new
      math = Ox::Element.new('math')
      math = Latexmath::XML::Element.new(@doc, 'math', { xmlns: xmlns, display: display })
      mrow = Latexmath::XML::Element.new(math, 'mrow')

      classify_subgroup(@aggregate, mrow)

      Ox.dump(@doc)
    end

    private

    def classify(element, parent, is_math_mode = false)
      symbol = Latexmath::Symbol.get(element)
      if element == '\\displaystyle'
      elsif element.nil?
        Latexmath::XML::Element.new(parent, 'mi')
      elsif element.match?(/^\d+(.\d+)?$/)
        el = Latexmath::XML::Element.new(parent, 'mn')
        el.text = element
      elsif element.size > 0 && '<>&'.include?(element)
        el = Latexmath::XML::Element.new(parent, 'mo')
        el.text = { '<' => '&lt;', '>' => '&gt;', '&' => '&amp;' }[element]
      elsif element.size > 0 && '+-*/()='.include?(element)
        el = Latexmath::XML::Element.new(parent, 'mo')
        el.text = symbol.nil? ? element : "&#x#{symbol};"
        el.set_attribute('stretchy', false) if '()'.include?(element)
      elsif symbol &&
            (
                Range.new('2200'.to_i(16), '22FF'.to_i(16)).include?(symbol.to_i(16)) ||
                Range.new('2190'.to_i(16), '21FF'.to_i(16)).include?(symbol.to_i(16))
              ) ||
            symbol == '.'

        mo = Latexmath::XML::Element.new(parent, 'mo')
        mo.text = "&#x#{symbol};"
      elsif element.start_with?('\\textrm')
        el = Latexmath::XML::Element.new(parent, 'mtext')
        matches = element.match(/\\textrm{([^}]*)}/)
        el.text = matches[1]
      elsif element.start_with?('\\vec')
        el = Latexmath::XML::Element.new(parent, 'mover', {accent: 'true'})
        mi = Latexmath::XML::Element.new(el, 'mi')
        matches = element.match(/\\vec{([^}]*)}/)
        mi.text = matches[1]
        mo = Latexmath::XML::Element.new(el, 'mo', {stretchy: 'false'})
        mo.text = "&#x#{Latexmath::Symbol.get('\\vec')};"
      elsif element.start_with?('\\hat')
        el = Latexmath::XML::Element.new(parent, 'mover', {accent: 'true'})
        mi = Latexmath::XML::Element.new(el, 'mi')
        matches = element.match(/\\hat{([^}]*)}/)
        mi.text = matches[1]
        mo = Latexmath::XML::Element.new(el, 'mo', {stretchy: 'false'})
        mo.text = "&#x#{Latexmath::Symbol.get('\\hat')};"
      elsif element.start_with?('\\mbox')
        el = Latexmath::XML::Element.new(parent, 'mtext')
        matches = element.match(/\\mbox{([^}]*)}/)
        el.text = matches[1]
      elsif element.start_with?('\\')
        tag_name = is_math_mode ? 'mo' : 'mi'
        el = Latexmath::XML::Element.new(parent, tag_name)
        el.text = if symbol
                    "&#x#{symbol};"
                  elsif ['\\log', '\\ln', '\\tan', '\\sec', '\\cos', '\\sin', '\\cot', '\\csc'].include?(element)
                    element[1..element.size]
                  else
                    element
                  end
      else
        tag_name = is_math_mode ? 'mo' : 'mi'
        el = Latexmath::XML::Element.new(parent, tag_name)
        el.text = element
      end
    end

    def classify_subgroup(elements, row, is_math_mode = false)
      return if elements.size == 0

      iterable = Range.new(0, (elements.size - 1)).each_compat
      while i = iterable.next
        element = elements[i]
        if element.is_a?(Array)
          _row = Latexmath::XML::Element.new(row, 'mrow')
          classify_subgroup(element, _row, is_math_mode)
          is_math_mode = false
        elsif COMMANDS.keys.include?(element)
          convert_command(element, elements, i, iterable, row)
        elsif element.start_with?('\\math')
          is_math_mode = true
        else
          classify(element, row, is_math_mode)
        end
        begin
          iterable.peek
        rescue StandardError
          break
        end
      end
    end

    def convert_and_append_operator(symbol, parent)
      converted = Latexmath::Symbol.get(symbol)
      mo = Latexmath::XML::Element.new(parent, 'mo')
      mo.text = "&#x#{converted};"
    end

    def convert_array_content(param, parent, alignment = '')
      all_are_list = param.all? { |item| item.is_a?(Array) }

      if all_are_list
        param.each do |row|
          convert_array_array(row, parent, alignment)
        end
      else
        convert_array_row(param, parent, alignment)
      end
    end

    def convert_array_array(row, parent, alignment)
      if alignment&.include?('|')
        _alignment = []
        column_lines = []
        alignment.chars.each do |j|
          if j == '|'
            column_lines << 'solid'
          else
            _alignment << j
          end
          column_lines << 'none' if _alignment.size - column_lines.size == 2
        end
        parent.set_attribute('columnlines', column_lines.join(' '))
      else
        _alignment = alignment.chars
      end

      mtr = Latexmath::XML::Element.new(parent, 'mtr')
      iterable = Range.new(0, row.size - 1).each_compat

      has_row_line = false
      index = 0
      row_lines = []

      while i = iterable.next
        element = row[i]
        if element == '\\hline'
          row_lines << 'solid'
          has_row_line = true
          row_lines.insert(0, 'none')
          next
        end
        align = _alignment[index]

        mtd = if %w[r l c].include?(align)
          column_align = { 'r' => 'right', 'l' => 'left', 'c' => 'center' }.fetch(align, nil)
          Latexmath::XML::Element.new(mtr, 'mtd', { columnalign: column_align })
        else
          Latexmath::XML::Element.new(mtr, 'mtd')
        end

        if element.is_a?(Array)
          classify_subgroup(element, mtd)
        elsif COMMANDS.include?(element)
          convert_command(element, row, i, iterable, mtd)
        else
          classify(element, mtd)
        end
        index += 1
        begin
          iterable.peek
        rescue StandardError
          break
        end
      end

      parent.set_attribute('rowlines', row_lines.join(' ')) if row_lines.include?('solid')
    end

    def convert_array_row(param, parent, alignment = '')
      if alignment&.include?('|')
        _alignment = []
        column_lines = []
        alignment.chars.each do |j|
          if j == '|'
            column_lines << 'solid'
          else
            _alignment << j
          end
          column_lines << 'none' if _alignment.size - column_lines.size == 2
        end
        parent.set_attribute('columnlines', column_lines.join(' '))
      else
        _alignment = alignment.chars
      end

      row_lines = []
      row_count = 0

      if param.all?{|d| !d.is_a?(Array)}
        mtr = Latexmath::XML::Element.new(parent, 'mtr')
        param.each do |element  |
          mtd = Latexmath::XML::Element.new(mtr, 'mtd')
          classify(element, mtd)
        end
      else
        param.each do |row|
          next if row.nil?

          row_count += 1
          mtr = Latexmath::XML::Element.new(parent, 'mtr')
          iterable = Range.new(0, row.size - 1).each_compat

          index = 0
          has_row_line = false

          while i = iterable.next
            element = row[i]
            if element == '\\hline' && row_count > 1
              row_lines << 'solid'
              has_row_line = true
              next
            end
            align = _alignment[index]

            mtd = if %w[r l c].include?(align)
                    column_align = { 'r' => 'right', 'l' => 'left', 'c' => 'center' }.fetch(align, nil)
                    Latexmath::XML::Element.new(mtr, 'mtd', { columnalign: column_align })
                  else
                    Latexmath::XML::Element.new(mtr, 'mtd')
            end

            if element.is_a?(Array)
              classify_subgroup(element, mtd)
            else
              classify(element, mtd)
            end

            index += 1

            begin
              iterable.peek
            rescue StandardError
              break
            end
          end

          row_lines << 'none' if !has_row_line && row_count > 1
        end
      end


      parent.set_attribute('rowlines', row_lines.join(' ')) if row_lines.include?('solid')
    end

    def convert_command(element, elements, index, iterable, parent)
      get_prefix_element(element, parent)

      parent = Latexmath::XML::Element.new(parent, 'mstyle', { scriptlevel: '1' }) if element == '\\substack'

      params, tag, attributes = COMMANDS[element]

      if (elements.size - 1) < params
        mo = Latexmath::XML::Element.new(parent, 'mo')
        mo.text = element[1..element.size]
        return
      end

      new_parent = Latexmath::XML::Element.new(parent, tag, attributes)
      alignment = ''

      if MATRICES.include?(element) && (element.end_with?('*') || element == '\\array')
        index += 1
        alignment = elements[index]
        iterable.next
      end

      if LIMITS.include?(element)
        limit = Latexmath::XML::Element.new(new_parent, 'mo')
        limit.text = element[1..element.size]
      end

      Range.new(0, (params - 1)).each do |_j|
        index += 1
        param = elements[index]
        if element == '_' && index == 1 && param == '\\sum'
          new_parent.tag = 'munder'
          classify(param, new_parent)
        elsif element == '\\left' || element == '\\right'
          if param == '.'

          else
            symbol = Latexmath::Symbol.get(param)
            new_parent.text = symbol.nil? ? param : "&#x#{symbol};"
          end
        elsif element == '\\array'
          convert_array_content(param, new_parent, alignment)
        elsif MATRICES.include?(element)
          convert_matrix_content(
            param, new_parent, alignment, element == '\\substack'
          )
        else
          if param.is_a?(Array)
            _parent = Latexmath::XML::Element.new(new_parent, 'mrow')
            classify_subgroup(param, _parent)
          else
            classify(param, new_parent)
          end
        end
      end

      get_postfix_element(element, parent)
      if ['\\overline', '\\bar'].include?(element)
        mo = Latexmath::XML::Element.new(new_parent, 'mo', { stretchy: 'true' })
        mo.text = '&#x000AF;'
      elsif element == '\\underline'
        mo = Latexmath::XML::Element.new(new_parent, 'mo', { stretchy: 'true' })
        mo.text = '&#x00332;'
      elsif element == '\\overrightarrow'
        mo = Latexmath::XML::Element.new(new_parent, 'mo', { stretchy: 'true' })
        mo.text = '&#x02192;'
      end

      params.times do
        iterable.next
      end
    end

    def convert_matrix_content(param, parent, alignment, single_mtd = true)
      return if param.size == 0
      return unless param.is_a?(Array)

      all_are_list = param.all? { |item| item.is_a?(Array) }

      if all_are_list
        param.each do |row|
          if row.empty?
            mtr = Latexmath::XML::Element.new(parent, 'mtr')
            Latexmath::XML::Element.new(mtr, 'mtd')
          else
            convert_matrix_row(row, parent, alignment, single_mtd)
          end
        end
      else
        convert_matrix_row(param, parent, alignment, single_mtd)
      end
    end

    def convert_matrix_row(row, parent, alignment, single_mtd)
      mtr = Latexmath::XML::Element.new(parent, 'mtr')
      iterable = Range.new(0, row.size - 1).each_compat
      mtd = Latexmath::XML::Element.new(mtr, 'mtd') if single_mtd

      while i = iterable.next
        element = row[i]
        if %w[r l c].include?(alignment)
          column_align = { 'r' => 'right', 'l' => 'left', 'c' => 'center' }.fetch(alignment, nil)
          mtd = Latexmath::XML::Element.new(mtr, 'mtd', { columnalign: column_align })
        elsif !single_mtd
          mtd = Latexmath::XML::Element.new(mtr, 'mtd')
        end

        if element.is_a?(Array)
          classify_subgroup(element, mtd)
        elsif COMMANDS.include?(element)
          convert_command(element, row, i, iterable, mtd)
        else
          classify(element, mtd)
        end
        begin
          iterable.peek
        rescue StandardError
          break
        end
      end
    end

    def get_postfix_element(element, row)
      if ['\\binom', '\\pmatrix'].include?(element)
        convert_and_append_operator('\\rparen', row)
      elsif element == '\\bmatrix'
        convert_and_append_operator('\\rbrack', row)
      elsif element == '\\Bmatrix'
        convert_and_append_operator('\\rbrace', row)
      elsif element == '\\vmatrix'
        convert_and_append_operator('\\vert', row)
      elsif element == '\\Vmatrix'
        convert_and_append_operator('\\Vert', row)
      end
    end

    def get_prefix_element(element, row)
      if ['\\binom', '\\pmatrix'].include?(element)
        convert_and_append_operator('\\lparen', row)
      elsif element == '\\bmatrix'
        convert_and_append_operator('\\lbrack', row)
      elsif element == '\\Bmatrix'
        convert_and_append_operator('\\lbrace', row)
      elsif element == '\\vmatrix'
        convert_and_append_operator('\\vert', row)
      elsif element == '\\Vmatrix'
        convert_and_append_operator('\\Vert', row)
      end
    end
  end
end
