class TwShowStatusViewController < UIViewController
  extend IB

  attr_writer :status

  def viewDidLoad
    url = @status["entities"]["media"].first["media_url"]
    url = NSURL.URLWithString url if url.is_a?(String)
    image = UIImage.imageWithData(NSData.dataWithContentsOfURL(url))
    imageView = view.subviews.first
    imageView.userInteractionEnabled = true
    imageView.image = image

    navigationController.navigationBarHidden = false
    navigationController.toolbarHidden = false
  end

  def view_tapped sender
    if navigationController.toolbarHidden?
      navigationController.navigationBarHidden = false
      navigationController.toolbarHidden = false
    else
      navigationController.navigationBarHidden = true
      navigationController.toolbarHidden = true
    end
  end

  def on_reblog
    self.performSegueWithIdentifier("TumblrPost", sender:self)
  end

  def prepareForSegue segue, sender:sender
    controller = segue.destinationViewController
    case segue.identifier
    when "TumblrPost"
      controller.status = @status
      controller.image = view.subviews.first.image
    end
  end
end
