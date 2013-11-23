class NSURL
  def fetch_image
    image_cache = ImageCache.get(self.absoluteString)
    unless image_cache
      NSLog("image cacheing: #{self.absoluteString}")
      data = NSData.dataWithContentsOfURL(self)
      image_cache = ImageCache.put(self.absoluteString, data)
    else
      # NSLog("find cached image: #{self.absoluteString}")
    end
    UIImage.imageWithData(image_cache.data) if image_cache
  end
end
