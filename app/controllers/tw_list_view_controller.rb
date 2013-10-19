# -*- coding: utf-8 -*-
class TwListViewController < UITableViewController
  extend IB

  def viewDidLoad
    NSNotificationCenter.defaultCenter.addObserver(self,
                                                   selector:'applicationDidBecomeActive',
                                                   name:UIApplicationDidBecomeActiveNotification,
                                                   object:nil)
    navigationController.interactivePopGestureRecognizer.enabled = true
  end

  def viewDidAppear animated
    if @reserve_open_settings
      open_settings
    end
  end

  # 起動時にTwitterアカウントがまだなければ設定画面を開く
  def applicationDidBecomeActive
    account = App.shared.delegate.twitter_account
    @reserve_open_settings = nil
    unless account
      @reserve_open_settings = true
    else
      reload(self)
    end
  end

  def settings sender
    open_settings
  end

  def open_settings
    self.performSegueWithIdentifier("ShowSettings", sender:self)
  end

  def reload sender
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
    list = @data[indexPath.row]
    cell.textLabel.text = list["name"]
    cell.detailTextLabel.text = list["description"]
    cell
  end

  def tableView tableView, didSelectRowAtIndexPath:indexPath
    @selected_list = @data[indexPath.row]
    self.performSegueWithIdentifier("ListStatuses", sender:self)
  end

  def prepareForSegue segue, sender:sender
    controller = segue.destinationViewController
    case segue.identifier
    when "ListStatuses"
      controller.list = @selected_list
    when "ShowSettings"
    end
  end
end
