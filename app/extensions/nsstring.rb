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

  def nil_then_blank
    self
  end
end
