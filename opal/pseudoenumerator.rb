# Opal doesn't support Enumerator's #next and #peek extended methods. This tries
# to emulate them.

class Pseudoenumerator
  def initialize obj
    @obj = obj.to_a.reverse
  end

  def next
    out = peek
    @obj.pop
    out
  end

  def peek
    raise StopIteration if @obj.length == 0
    @obj.last
  end
end
