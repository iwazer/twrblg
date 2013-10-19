class TumblrBlog
  attr_reader :name, :title, :primary

  def initialize name, title, primary
    @name = name
    @title = title
    @primary = primary
  end

  def pack
    [name, title, primary].join("\2")
  end

  def inspect
    [name, title, primary].join(" ")
  end
end

class TumblrAccount
  attr_reader :name, :blogs

  def initialize arg
    if arg.is_a?(Hash)
      @name = arg["name"]
      @blogs = []
      arg["blogs"].each do |blog|
        @blogs << TumblrBlog.new(blog["name"],blog["title"],blog["primary"])
      end
    elsif arg.is_a?(String)
      @name = arg
    end
  end

  def << blog
    @blogs ||= []
    @blogs << blog
  end

  def self.unpack s
    if s.present?
      info = s.split("\1")
      if info.select(&:present?).count > 0
        name = info.shift
        account = TumblrAccount.new(name)
        info.map do |bs|
          binfo = bs.split("\2")
          if binfo.select(&:present?).count == 3
            account.blos << TumblrBlog.new(*binfo)
          end
        end
        account
      end
    end
  end

  def pack
    [name, blogs.map(&:pack)].join("\1")
  end

  def inspect
    [name, blogs.map(&:inspect)].join("\1")
  end
end
