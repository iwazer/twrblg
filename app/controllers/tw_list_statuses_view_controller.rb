class TwListStatusesViewController < UITableViewController
  extend IB

  attr_writer :list

  def viewDidLoad
    self.title = @list["description"].blank_then_nil || @list["name"]
    @data = []
    @count = 5
    fetch_statuses
  end

  def fetch_statuses
    account = App.shared.delegate.twitter_account
    if account
      twitter = App.shared.delegate.twitter
      successBlock = lambda {|statuses|
        @data += fetch_images(statuses)
      }
      twitter.getListsStatusesForListID(@list["id_str"],
                                        sinceID: @since_id,
                                        maxID: @max_id,
                                        count: @count,
                                        includeEntities: nil,
                                        includeRetweets: 0,
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
    @data.count + 1
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
    if indexPath.row < @data.count
      status = @data[indexPath.row]
      if status["user"] && status["user"]["profile_image_url"].present?
        url = status["user"]["profile_image_url"]
        image = url.nsurl.fetch_image
        cell.imageView.image = image
      end
      if status["_image_url"]
        cell.styleClass = "exist-image-cell"
      else
        cell.styleClass = "no-image-cell"
      end
      cell.detailTextLabel.text = status["text"]
    else
      cell.detailTextLabel.text = "Older"
      cell.imageView.image = nil
      cell.styleClass = "exist-image-cell"
    end
    cell
  end

  def tableView tableView, didSelectRowAtIndexPath:indexPath
    if indexPath.row < @data.count
      @status = @data[indexPath.row]
      if @status["_image_url"]
        self.performSegueWithIdentifier("TbrPostView", sender:self)
      else
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
      end
    else
      @since_id = nil
      @max_id = @data[-1]["id"].to_i - 1
      fetch_statuses
    end
  end

  def fetch_images statuses
    data = statuses.map{|s| s.mutableCopy}
    data.each do |status|
      unless status["_image_url"]
        candidate_image_url(status)
      end
    end
    NSTimer.scheduledTimerWithTimeInterval(0.5,
                                           target: self,
                                           selector: "refresh:",
                                           userInfo: nil,
                                           repeats: true)
    data
  end

  def prepareForSegue segue, sender:sender
    if segue.identifier == "TbrPostView"
      if @status["_image_url"]
        controller = segue.destinationViewController
        controller.status = @status
      end
    end
  end

  def candidate_image_url status
    entities = status["entities"]
    if entities["media"]
      set_status(status, entities["media"].first["media_url"],
                 status["entities"]["media"].first["expanded_url"])
    elsif entities["urls"].try(:count) > 0
      main_image_url(status)
    else
      status["_processed"] = true
    end
  end

  def main_image_url status
    no_image = true
    status["entities"]["urls"].each do |h|
      url = h["expanded_url"]
      case url
      when %r{twitpic.com/}
        find_image_url(status, url.concat("/full").gsub("//", "/"),
                       '//meta[@name="twitter:image"]', 'value')
        no_image = false
        break
      when %r{twicolle.com/}
        find_image_url(status, url, '//img[@itemprop="image"]', 'src')
        no_image = false
        break
      when %r{inupple.com/}
        find_image_url(status, url, '//meta[@name="twitter:image:src"]', 'content')
        no_image = false
        break
      end
    end
    status["_processed"] = true if no_image
  end

  def refresh timer
    if @data.select{|status| status["_processed"].nil?}.count == 0
      tableView.reloadData
      timer.invalidate
    end
  end

  def find_image_url status, url, xpath, attr
    begin
      NSLog("access to #{url}")
      BW::HTTP.get(url) do |response|
        parser = Hpple.HTML(response.body.to_s)
        meta = parser.xpath(xpath).first
        if meta && meta[attr]
          set_status(status, meta[attr], url)
        else
          status["_processed"] = true
        end
      end
    rescue Exception => e
      NSLog(e.message)
      status["_processed"] = true
    end
  end

  def set_status status, img_url, src_url
    status["_image_url"] = img_url
    status["_image"] = status["_image_url"].to_s.nsurl.fetch_image
    status["_link"] = src_url
    status["_processed"] = true
  end
end
