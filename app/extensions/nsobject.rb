class NSObject
  def try name, *args
    unless self.is_a?(NilClass)
      self.send(name, *args)
    end
  end
end
