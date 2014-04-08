class ImageCache < CDQManagedObject

  class << self
    def get url
      @@memory_cache ||= LruCache.new(200)
      cache = @@memory_cache.read(url)
      unless cache
        cache = where(url: url).first
        @@memory_cache.store(url, cache) if cache
      end
      cache
    end

    def put url, data
      val = nil
      cdq.contexts.new(NSMainQueueConcurrencyType) do
        cache = create(url: url, data: data, created_at: Time.now, referred_at: Time.now)
        cdq.save
        val = @@memory_cache.store(url, cache)
      end
      val
    end
  end

end
