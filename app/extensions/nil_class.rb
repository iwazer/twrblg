class NilClass
  def blank?
    true
  end

  def present?
    false
  end

  def count
    0
  end

  def blank_then_nil
    self
  end

  def nil_then_blank
    ""
  end

  def empty?
    true
  end

  def try name, *args
    nil
  end
end
