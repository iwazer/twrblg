class TwListStatusesViewController < UITableViewController
  extend IB

  attr_writer :list

  def viewDidLoad
    self.title = @list["description"].blank_then_nil || @list["name"]
  end
end
