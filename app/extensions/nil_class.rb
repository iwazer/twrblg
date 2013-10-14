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

  def empty?
    true
  end
end
