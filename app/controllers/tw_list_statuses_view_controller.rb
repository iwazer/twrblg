class TwListStatusesViewController < UITableViewController
  extend IB

  attr_writer :list

  def viewDidLoad
    self.title = @list["description"].blank_then_nil || @list["name"]

    fetch_statuses
  end

  def fetch_statuses
    account = App.shared.delegate.twitter_account
    if account
      twitter = App.shared.delegate.twitter
      successBlock = lambda {|statuses|
        @data = statuses.select{|status| media_photo?(status)}
        self.tableView.reloadData
      }
      twitter.getListsStatusesForListID(@list["id_str"],
                                        sinceID: @since_id,
                                        maxID: nil,
                                        count: @count,
                                        includeEntities: nil,
                                        includeRetweets: 0,
                                        successBlock: successBlock,
                                        errorBlock: lambda {|error|
                                          App.alert(error.localizedDescription.to_s)
                                        })
    end
  end

  def media_photo? status
    status["entities"] &&
      !status["entities"]["media"].empty? &&
      status["entities"]["media"].first["type"] == "photo"
  end

  def numberOfSectionsInTableView tableView
    1
  end

  def tableView tableView, numberOfRowsInSection: section
    @data.count
  end

  def tableView tableView, cellForRowAtIndexPath: indexPath
    @@cellIdentifier = "TwitterStatusCell"
    cell = tableView.dequeueReusableCellWithIdentifier(@@cellIdentifier)
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(
        UITableViewCellStyleSubtitle, reuseIdentifier:@@cellIdentifier)
      cell.textLabel.minimumScaleFactor = 10.0/15
      cell.textLabel.adjustsFontSizeToFitWidth = true
    end
    status = @data[indexPath.row]
    if status["user"] && status["user"]["profile_image_url"].present?
      url = status["user"]["profile_image_url"]
      image = UIImage.imageWithData(NSData.dataWithContentsOfURL(NSURL.URLWithString(url)))
      cell.imageView.image = image
    end
    cell.detailTextLabel.text = status["text"]
    cell
  end

  def tableView tableView, didSelectRowAtIndexPath:indexPath
    @status = @data[indexPath.row]
    self.performSegueWithIdentifier("TbrPostView", sender:self)
  end

  def prepareForSegue segue, sender:sender
    if segue.identifier == "TbrPostView"
      controller = segue.destinationViewController
      controller.status = @status
      url = @status["entities"]["media"].first["media_url"]
      url = NSURL.URLWithString url if url.is_a?(String)
      controller.image = UIImage.imageWithData(NSData.dataWithContentsOfURL(url))
    end
  end
end
