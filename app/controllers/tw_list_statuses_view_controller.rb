# -*- coding: undecided -*-
class TwListStatusesViewController < UITableViewController
  extend IB

  attr_writer :list

  FETCH_COUNT = 5

  def viewDidLoad
    self.title = @list["description"].blank_then_nil || @list["name"]
    @data = Struct.new(:rows, :gap_id).new([])
    @count = 5
    @list_id = @list["id"].to_i
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
      @data.rows = statuses
      refresh(nil)
      fetch_statuses(:top)
    }
    start_activity_indicator
    TwitterStatus.load_statuses(@list_id, completed)
  end

  def fetch_statuses gap=:bottom
    success = -> (statuses) {
      data = statuses.map{|status| TwitterStatus.from_api(@list_id, status)}
      fetch_images(data, gap)
    }
    start_activity_indicator
    twitter = App.shared.delegate.twitter
    twitter.getListsStatusesForListID(@list_id,
                                      sinceID: @since_id,
                                      maxID: @max_id,
                                      count: FETCH_COUNT,
                                      includeEntities: nil,
                                      includeRetweets: nil,
                                      successBlock: success,
                                      errorBlock: -> (error) {
                                        App.alert(error.localizedDescription.to_s)
                                      })
  end

  def numberOfSectionsInTableView tableView
    1
  end

  def tableView tableView, numberOfRowsInSection: section
    @data.rows.count + 1
  end

  def tableView tableView, cellForRowAtIndexPath: indexPath
    @@gapCellIdentifier = "GapCell"
    status = @data.rows[indexPath.row]
    if !status || status.gap?
      tableView.dequeueReusableCellWithIdentifier(@@gapCellIdentifier,
                                                  forIndexPath:indexPath)
    else
      @@cellIdentifier = "TwitterStatusCell"
      cell = tableView.dequeueReusableCellWithIdentifier(@@cellIdentifier,
                                                         forIndexPath:indexPath)
      cell_clear(cell)
      if status.profile_image_url
        image = status.profile_image_url.nsurl.fetch_image
        cell.image_view.image = image
      end
      cell.name_view.text = "#{status.display_name}(#{status.user_id})"
      cell.status_view.text = status.text
      cell.time_view.text = status.created_at.strftime("%Y/%m/%d %H:%M")
      if status.image_url
        cell.styleClass = "exist-image-cell"
      else
        cell.styleClass = "no-image-cell"
      end
      cell
    end
  end

  def cell_clear cell
    cell.image_view.image = nil
    cell.name_view.text = nil
    cell.time_view.text = nil
    cell.status_view.text = nil
    #cell.styleClass = "exist-image-cell"
  end

  def tableView tableView, didSelectRowAtIndexPath:indexPath
    if indexPath.row < @data.rows.count
      @status = @data.rows[indexPath.row]
      return unless @status
      if @status.gap? && indexPath.row > 0
        @max_id = @status.below_me_max
        @since_id = @data.gap_id = @data.rows[indexPath.row + 1].status_id
        @data.rows.delete_at(indexPath.row)
        @status.destroy
        fetch_statuses(:gap)
      elsif @status.image_url
        self.performSegueWithIdentifier("TbrPostView", sender:self)
      else
        App.alert("画像がないつぶやきです")
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
      end
    else
      @since_id = nil
      @max_id = @data.rows[-1].status_id - 1
      fetch_statuses
    end
  end

  def fetch_images data, gap
    overlap_new = []
    overlap_pre = []
    data.each do |status|
      if @data.rows.find{|st| st.status_id==status.status_id}
        if @data.gap_id && @data.gap_id > st.id
          overlap_new << status
        else
          overlap_pre << status
        end
      else
        candidate_image_url(status)
      end
    end
    data -= (overlap_new + overlap_pre)
    if gap != :bottom && overlap_pre.empty? && !data.empty? && !@data.rows.empty?
      data << TwitterStatus.create_gap(@list_id, data[-1].status_id)
    end
    unless data.empty?
      case gap
      when :top
        @data.rows = data + @data.rows
      when :gap
        insert_index = nil
        @data.rows.each_with_index.each do |status, i|
          if status.id < data.first.id
            insert_index = i
            break
          end
        end
        if insert_index
          @data.rows.insert(insert_index, data).flatten!
        end
      else
        @data.rows += data
      end
    end
    NSTimer.scheduledTimerWithTimeInterval(1,
                                           target: self,
                                           selector: "refresh:",
                                           userInfo: nil,
                                           repeats: true)
  end

  def prepareForSegue segue, sender:sender
    if segue.identifier == "TbrPostView"
      if @status.image_url
        controller = segue.destinationViewController
        controller.status = @status
      end
    end
  end

  def candidate_image_url status
    return unless status.original
    entities = status.original["entities"]
    if entities["media"]
      set_status(status, entities["media"].first["media_url"],
                 entities["media"].first["expanded_url"])
    elsif entities["urls"].try(:count) > 0
      main_image_url(status)
    else
      status.done
    end
  end

  def main_image_url status
    no_image = false
    status.original["entities"]["urls"].each do |h|
      url = h["expanded_url"]
      case url
      when %r{twitpic.com/}
        find_image_url(status, url.concat("/full").gsub("//", "/"),
                       '//meta[@name="twitter:image"]', 'value')
        break
      when %r{/twicolle.com/}
        find_image_url(status, url, '//img[@itemprop="image"]', 'src')
        break
      when %r{inupple.com/}
        find_image_url(status, url, '//meta[@name="twitter:image:src"]', 'content')
        break
      when %r{imgur.com/}
        url = url[0..-5] if url[-4..-1] == ".jpg"
        set_status(status, "#{url}.jpg", url)
        break
      when %r{yfrog.com/}
        find_image_url(status, url.gsub("/yfrog.com/", "/twitter.yfrog.com/").concat("?sa=0"),
                       '//meta[@name="twitter:image"]', 'value')
        break
      else
        no_image = true
      end
    end
    status.done if no_image
  end

  def refresh timer
    tags = @data.rows.reject do |status|
      status.try(:processed)
    end
    if tags.count == 0
      if timer
        timer.invalidate
        @end_refreshing.try(:call)
        @end_refreshing = nil
        tableView.reloadData
        stop_activity_indicator
      end
    end
  end

  def find_image_url status, url, xpath, attr
    NSLog("access to #{url}")
    BW::HTTP.get(url) do |response|
      begin
        parser = Hpple.HTML(response.body.to_s)
        meta = parser.xpath(xpath).first
        if meta && meta[attr]
          set_status(status, meta[attr], url)
        else
          status.done
        end
      rescue Exception => e
        NSLog(e.message)
        status.done
      end
    end
  end

  def set_status status, img_url, src_url
    status.image_url = img_url
    status.link = src_url
    status.done
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
