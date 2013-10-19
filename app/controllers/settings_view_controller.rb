class SettingsViewController < UITableViewController
  extend IB

  def viewDidLoad
    self.title = "Settings"

    @data = [{
               name: "Twitter Account",
               account: App.shared.delegate.twitter_account,
               type: :twitter
             },
             {
               name: "Tumblr Blog",
               account: App.shared.delegate.tumblr_account,
               type: :tumblr
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
    cell.update_status(setting[:account])
    cell
  end

  def tableView tableView, didSelectRowAtIndexPath:indexPath
    case @data[indexPath.row][:type]
    when :twitter
      twitter_authorize
    when :tumblr
    end
  end

  def twitter_authorize
    twitter = App.shared.delegate.twitter(true)
    successBlock = -> (url, oauthToken) {
      controller = TwPinViewController.new
      controller.url = url
      controller.callback_at_poped = -> (account) {
        type = account.is_a?(TwitterAccount) ? 0 : 1
        @data[type][:account] = account
        self.tableView.reloadData
      }
      navigationController.pushViewController(controller,
                                              animated:true)
    }
    twitter.postTokenRequest(successBlock,
                             oauthCallback: "",
                             errorBlock: -> (error) {
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

  def dismiss target
    navigationController.dismiss.call
  end
end
