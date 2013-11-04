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
end

class TumblrAccount
  attr_reader :name, :token, :token_secret
  attr_accessor :default_blog_index

  def initialize user_info, token, token_secret, default_blog_index=0
    if user_info.is_a?(Hash)
      @name = user_info["name"]
      @token = token
      @token_secret = token_secret
      @default_blog_index = default_blog_index
      @blogs = []
      user_info["blogs"].each do |blog|
        @blogs << TumblrBlog.new(blog["name"],blog["title"],blog["primary"])
      end
    elsif user_info.is_a?(String)
      @name = user_info
      @token = token
      @token_secret = token_secret
      @default_blog_index = default_blog_index
    end
  end

  def blogs
    @blogs ||= []
  end

  def << blog
    blogs << blog
  end

  def self.unpack s
    if s.present?
      info = s.split("\1")
      if info.select(&:present?).count > 0
        name = info.shift
        token = info.shift
        token_secret = info.shift
        default_blog_index = info.shift.to_i
        account = TumblrAccount.new(name, token, token_secret, default_blog_index)
        info.map do |bs|
          binfo = bs.split("\2")
          if binfo.select(&:present?).count == 3
            account.blogs << TumblrBlog.new(*binfo)
          end
        end
        account
      end
    end
  end

  def pack
    [name, token, token_secret, default_blog_index, blogs.map(&:pack)].join("\1")
  end
end
