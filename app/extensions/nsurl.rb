class NSURL
  def fetch_image
    UIImage.imageWithData(NSData.dataWithContentsOfURL(self))
  end
end
