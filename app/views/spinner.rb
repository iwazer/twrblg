module Spinner
  def setup_spinner view
    @super_view = view
    @activity_indicator = UIActivityIndicatorView.alloc
      .initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleWhiteLarge)
    view.addSubview(@activity_indicator)
  end

  def start_activity_indicator
    unless @spinner
      frame = @super_view.frame
      @spinner = @activity_indicator
      @spinner.center = [frame.size.width/2, frame.size.height/2 + view.contentOffset.y]
      @spinner.startAnimating
    end
  end

  def stop_activity_indicator
    if @spinner
      @spinner.stopAnimating
      @spinner = nil
    end
  end
end
