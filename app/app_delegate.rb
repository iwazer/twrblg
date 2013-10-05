class AppDelegate
  attr_accessor :window
  attr_reader :twitter

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    true
  end

  def applicationDidBecomeActive application
    unless @twitter
      consumer_key = 'TW-CONSUMER-KEY'.info_plist
      secret_key = 'TW-SECRET-KEY'.info_plist
      @twitter = STTwitterAPI.twitterAPIAppOnlyWithConsumerKey(consumer_key,
                                                               consumerSecret:secret_key)
    end
  end
end
