class TwListStatusesViewController < UITableViewController
  extend IB

  attr_writer :list

  FETCH_COUNT = 5

  def viewDidLoad
    self.title = @list["description"].blank_then_nil || @list["name"]
    @data = []
    @count = 5
    @list_id = @list["id"]
    NSLog("Show list #{@list_id} statuses")
    setup_spinner(view)
    account = App.shared.delegate.twitter_account
    if account
      load_statuses
    end

    refresh_control = UIRefreshControl.alloc.init
    refresh_control.attributedTitle = NSAttributedString.alloc.initWithString("pull to Refresh")
    refresh_control.addTarget(self,
                              action: "refresh_table_view",
                              forControlEvents: UIControlEventValueChanged)
    self.refreshControl = refresh_control
  end

  def load_statuses
    completed = -> (statuses) {
      data = statuses.map(&:status)
      @data = []
      data.each do |status|
        @data << status
        @data << {gap: true, "_processed" => true, "_stored" => true} unless status["_prev_id"]
      end
      @data.pop if @data.last.try(:[], :gap)
      refresh nil
      fetch_statuses(:top)
    }
    start_activity_indicator
    TwitterStatus.load_statuses(@list_id, completed)
    
  end

  def fetch_statuses gap=:bottom
    success = -> (statuses) {
      data = statuses.map{|s| s.mutableCopy}
      store_prev_id(data)
      fetch_images(data, gap)
    }
    start_activity_indicator
    twitter = App.shared.delegate.twitter
    twitter.getListsStatusesForListID(@list_id,
                                      sinceID: @since_id,
                                      maxID: @max_id,
                                      count: FETCH_COUNT,
                                      includeEntities: nil,
                                      includeRetweets: 0,
                                      successBlock: success,
                                      errorBlock: -> (error) {
                                        App.alert(error.localizedDescription.to_s)
                                      })
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
      cell.textLabel.minimumScaleFactor = 10.0/18
      cell.textLabel.adjustsFontSizeToFitWidth = true
      cell.detailTextLabel.minimumScaleFactor = 10.0/18
      cell.detailTextLabel.adjustsFontSizeToFitWidth = true
    end
    cell_clear(cell)
    if indexPath.row < @data.count
      status = @data[indexPath.row]
      if status[:gap]
        cell.detailTextLabel.text = "fetch for non-acquisition..."
        cell.styleClass = "exist-image-cell"
      else
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
        cell.textLabel.text = status["text"]
        info = "#{parse_dt(status["created_at"]).strftime("%Y/%m/%d %H:%M:%S")} #{status["id"]}"
        cell.detailTextLabel.text = info
      end
    else
      cell.detailTextLabel.text = "Older"
      cell.imageView.image = nil
      cell.styleClass = "exist-image-cell"
    end
    cell
  end

  def cell_clear cell
    cell.detailTextLabel.text = nil
    cell.textLabel.text = nil
    cell.imageView.image = nil
    cell.styleClass = nil
  end

  def tableView tableView, didSelectRowAtIndexPath:indexPath
    if indexPath.row < @data.count
      @status = @data[indexPath.row]
      if @status[:gap] && indexPath.row > 0
        @max_id = @data[indexPath.row-1]["id"].to_i - 1
        fetch_statuses(:gap)
      elsif @status["_image_url"]
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

  def fetch_images data, gap
    overlap = []
    data.each do |status|
      if @data.find{|st| st["id"]==status["id"]}
        overlap << status
      else
        candidate_image_url(status)
      end
    end
    data -= overlap
    if overlap.empty?
      data << {gap: true, "_processed" => true, "_stored" => true}
    end
    unless data.empty?
      last = first = nil
      case gap
      when :top
        last = data.last
        first = @data.first
        @data = data + @data
      when :gap
        insert_index = nil
        @data.each_with_index.each do |status, i|
          if status["id"].to_i > data.first["id"].to_i
            insert_index = i
          else
            break
          end
        end
        if insert_index
          last = @data[insert_index]
          first = data.first
          @data.insert(insert_index, data).flatten!
          @data.delete_at(insert_index+1)
        end
      else
        last = @data.last
        first = data.first
        @data += data
      end
      if last && first
        last["_prev_id"] = first["id"]
        last["_stored"] = nil
      end
    end
    @data.pop if @data.last.try(:[], :gap)
    NSTimer.scheduledTimerWithTimeInterval(1,
                                           target: self,
                                           selector: "refresh:",
                                           userInfo: nil,
                                           repeats: true)
  end

  def store_prev_id statuses
    next_stt = nil
    statuses.each do |status|
      next_stt["_prev_id"] = status["id"] if next_stt
      next_stt = status
    end
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
      when %r{twitpic.com/}, %r{http://imgur.com/}
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
      timer.invalidate if timer
      tableView.reloadData
      for_store = @data.reject{|status| status["_stored"]}
      TwitterStatus.store_statuses(@list_id, for_store)
      for_store.each {|status| status["_stored"] = true}
      @end_refreshing.try(:call)
      @end_refreshing = nil
      stop_activity_indicator
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
    status["_link"] = src_url
    status["_processed"] = true
  end

  def refresh_table_view
    refreshControl.attributedTitle =
      NSAttributedString.alloc.initWithString("Refreshing the TableView")
    @end_refreshing = -> {
      lastupdated = Time.now.strftime("Last Updated on %Y/%m/%d %H:%M:%S")
      refreshControl.attributedTitle = NSAttributedString.alloc.initWithString(lastupdated)
      refreshControl.endRefreshing
    }
    fetch_statuses(:top)
  end

  include Spinner
  include DateFormat
end
