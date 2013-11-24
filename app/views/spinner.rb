module Spinner
  def setup_spinner view
    @activity_indicator = UIActivityIndicatorView.alloc
      .initWithActivityIndicatorStyle(UIActivityIndicatorViewStyleWhiteLarge)
    @activity_indicator.center = [CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)]
    view.addSubview(@activity_indicator)
  end

  def start_activity_indicator
    puts 'start_activity_indicator'
    unless @spinner
      @spinner = @activity_indicator
      @spinner.startAnimating
    end
  end

  def stop_activity_indicator
    puts 'stop_activity_indicator'
    if @spinner
      @spinner.stopAnimating
      @spinner = nil
    end
  end
end
