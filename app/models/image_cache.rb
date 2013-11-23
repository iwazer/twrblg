class ImageCache < NanoStore::Model
  attribute :url
  attribute :data
  attribute :created_at
  attribute :referred_at

  class << self
    def get url
      @@memory_cache ||= LruCache.new(200)
      cache = @@memory_cache.read(url)
      unless cache
        cache = find(url: url).first
        @@memory_cache.store(url, cache) if cache
      end
      cache
    end

    def put url, data
      cache = create(url: url, data: data, created_at: Time.now, referred_at: Time.now)
      @@memory_cache.store(url, cache)
    end
  end
end
