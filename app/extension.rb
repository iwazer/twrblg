class NSString
  def blank?
    self.empty? or /^\s+$/ =~ self
  end

  def present?
    !self.blank?
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
end
