class TwShowStatusViewController < UIViewController
  extend IB

  attr_writer :status

  def viewDidLoad
    url = @status["entities"]["media"].first["media_url"]
    url = NSURL.URLWithString url if url.is_a?(String)
    image = UIImage.imageWithData(NSData.dataWithContentsOfURL(url))
    imageView = view.subviews.first
    imageView.image = image
  end
end
