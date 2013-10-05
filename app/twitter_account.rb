class TwitterAccount
  attr_reader :user_id, :screen_name, :oauth_token, :oauth_token_secret

  def initialize user_id, oauth_token, oauth_token_secret, screen_name
    @user_id = user_id
    @oauth_token = oauth_token
    @oauth_token_secret = oauth_token_secret
    @screen_name = screen_name
  end

  def self.unpack s
    if s.present?
      info = s.split("\1")
      if info.select(&:present?).count == 4
        TwitterAccount.new(*info)
      end
    end
  end

  def pack
    [user_id, oauth_token, oauth_token_secret, screen_name].join("\1")
  end

  def inspect
    [user_id, oauth_token, oauth_token_secret, screen_name].join(" ")
  end
end
