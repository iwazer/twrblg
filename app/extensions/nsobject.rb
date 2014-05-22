class NSObject
  def try name, *args
    if self.respond_to?(name)
      self.send(name, *args)
    end
  end
end
