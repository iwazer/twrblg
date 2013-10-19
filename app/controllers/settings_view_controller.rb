class SettingsViewController < UITableViewController
  extend IB

  def viewDidLoad
    self.title = "Settings"

    @data = [{
               name: "Twitter Account",
               account: App.shared.delegate.twitter_account
             },
             {
               name: "Tumblr Blog",
               account: App.shared.delegate.tumblr_account
             }]
  end

  def numberOfSectionsInTableView tableView
    1
  end

  def tableView tableView, numberOfRowsInSection: section
    @data.count
  end

  def tableView tableView, cellForRowAtIndexPath: indexPath
    cell = tableView.dequeueReusableCellWithIdentifier("SettingsViewCell")
    setting = @data[indexPath.row]
    cell.textLabel.text = setting[:name]
    #cell.update_status() #TODO
    cell
  end

  def twitter_authorize
    twitter = App.shared.delegate.twitter
    callback_at_poped = lambda { self.reload(self) }
    successBlock = lambda {|url, oauthToken|
      controller = TwPinViewController.new
      controller.url = url
      controller.callback_at_poped = callback_at_poped
      navigationController.pushViewController(controller,
                                              animated:true)
    }
    twitter.postTokenRequest(successBlock,
                             oauthCallback: "",
                             errorBlock: lambda { |error|
                               App.alert(error.localizedDescription.to_s)
                             })
  end

  def tumblr_authenticate
    TMAPIClient.sharedInstance.authenticate("com.iwazer.twrblg", callback: -> (error) {
                                              unless error
                                                App.alert("Tumblr authorization is success")
                                              else
                                                msg = error.localizedDescription
                                                App.alert("Tumblr authorization is failed: #{msg}")
                                              end
                                            })
  end
end
