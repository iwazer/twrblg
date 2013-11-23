class NSURL
  def fetch_image
    image_cache = ImageCache.find(url: self.absoluteString).first
    image_data = unless image_cache
                   NSLog("image cacheing: #{self.absoluteString}")
                   data = NSData.dataWithContentsOfURL(self)
                   image_cache = ImageCache.create(url: self.absoluteString, data: data,
                                                   created_at: Time.now, referred_at: Time.now)
                 else
                   NSLog("find cached image: #{self.absoluteString}")
                 end
    UIImage.imageWithData(image_cache.data)
  end
end
