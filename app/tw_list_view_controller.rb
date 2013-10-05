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
        @data = lists
        self.tableView.reloadData
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

  def numberOfSectionsInTableView tableView
    1
  end

  def tableView tableView, numberOfRowsInSection: section
    @data.count
  end

  def tableView tableView, cellForRowAtIndexPath: indexPath
    @@cellIdentifier = "TwitterListCell"
    cell = tableView.dequeueReusableCellWithIdentifier(@@cellIdentifier)
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(
        UITableViewCellStyleSubtitle, reuseIdentifier:@@cellIdentifier)
      cell.textLabel.minimumScaleFactor = 10.0/15
      cell.textLabel.adjustsFontSizeToFitWidth = true
    end
    row = @data[indexPath.row]
    cell.textLabel.text = row["name"]
    cell.detailTextLabel.text = row["description"]
    cell
  end
end
