module KeyChainStore
  class << self
    def setString key, value
      UICKeyChainStore.setString(value.to_s, forKey:key.to_s)
    end

    def fetch key
      UICKeyChainStore.stringForKey(key.to_s)
    end
  end
end
