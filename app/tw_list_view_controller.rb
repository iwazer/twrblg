# -*- coding: utf-8 -*-
class TwListViewController < UITableViewController
  extend IB

  def viewDidLoad
    NSNotificationCenter.defaultCenter.addObserver(self,
                                                   selector:'applicationDidBecomeActive',
                                                   name:UIApplicationDidBecomeActiveNotification,
                                                   object:nil)
  end

  # 起動時にTwitterアカウントがまだなければOAuthToken/Secretを取得する
  def applicationDidBecomeActive
    account = App.shared.delegate.twitter_account
    unless account
      twitter = App.shared.delegate.twitter
      callback_at_poped = lambda { self.on_reload(self) }
      successBlock = lambda {|url, oauthToken|
        controller = TwPinViewController.new
        controller.url = url
        controller.callback_at_poped = callback_at_poped
        self.navigationController.pushViewController(controller,
                                                     animated:true)
      }
      twitter.postTokenRequest(successBlock,
                               oauthCallback: "",
                               errorBlock: lambda { |error|
                                 App.alert(error.localizedDescription.to_s)
                               })
    else
      on_reload(self)
    end
  end

  def on_reload sender
    account = App.shared.delegate.twitter_account
    if account
      twitter = App.shared.delegate.twitter
      successBlock = lambda {|lists|
        # TODO
      }
      twitter.getListsSubscribedByUsername(nil,
                                           orUserID: nil,
                                           reverse: 0,
                                           successBlock: successBlock,
                                           errorBlock: lambda {|error|
                                             App.alert(error.localizedDescription.to_s)
                                           })
    end
  end
end
