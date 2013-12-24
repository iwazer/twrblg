module DateFormat
  def parse_dt s
    dtf = NSDateFormatter.alloc.init
    dtf.setDateFormat("EEE MMM dd HH:mm:ss Z yyyy")
    dtf.dateFromString(s)
  end
end
