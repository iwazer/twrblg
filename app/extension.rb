class NSString
  def blank?
    self.empty? or /^\s+$/ =~ self
  end

  def present?
    !self.blank?
  end

  def blank_then_nil
    if self.blank?
      nil
    else
      self
    end
  end
end

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
end
