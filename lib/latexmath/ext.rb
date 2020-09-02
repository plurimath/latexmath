class Range
  def each_compat
    if RUBY_ENGINE == 'opal'
      Pseudoenumerator.new(self)
    else
      each
    end
  end
end
