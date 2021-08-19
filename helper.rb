class Object
  # File activesupport/lib/active_support/core_ext/object/blank.rb, line 18
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  # File activesupport/lib/active_support/core_ext/object/blank.rb, line 25
  def present?
    !blank?
  end

  # File activesupport/lib/active_support/core_ext/object/blank.rb, line 45
  def presence
    self if present?
  end
end
