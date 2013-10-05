class TwListViewController < UITableViewController
  def viewDidLoad
    NSNotificationCenter.defaultCenter.addObserver(self,
                                                   selector:'applicationDidBecomeActive',
                                                   name:UIApplicationDidBecomeActiveNotification,
                                                   object:nil)
  end

  def applicationDidBecomeActive
    account = App.shared.delegate.twitter_account
    unless account
      twitter = App.shared.delegate.twitter
      twitter.postTokenRequest(lambda { |url,oauthToken|
                                 controller = TwPinViewController.new
                                 controller.url = url
                                 self.navigationController.pushViewController(controller,
                                                                              animated:true)
                               },
                               oauthCallback: "",
                               errorBlock: lambda { |error|
                                 App.alert(error.localizedDescription.to_s)
                               })
    end
  end
end
