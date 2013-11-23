class AppDelegate
  attr_accessor :window
  attr_reader :twitter

  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window.styleMode = PXStylingNormal

    TMAPIClient.sharedInstance.OAuthConsumerKey = 'TM-CONSUMER-KEY'.info_plist
    TMAPIClient.sharedInstance.OAuthConsumerSecret = 'TM-SECRET-KEY'.info_plist

    account = tumblr_account
    if account
      TMAPIClient.sharedInstance.OAuthToken = account.token
      TMAPIClient.sharedInstance.OAuthTokenSecret = account.token_secret
    end

    NanoStore.shared_store = NanoStore.store(:file, "twrblg01.db".document)
    true
  end

  def application application,
    openURL: url, sourceApplication: sourceApplication, annotation: annotation
    TMAPIClient.sharedInstance.handleOpenURL(url)
  end

  def twitter reconnect=false
    twitter =
      begin
        consumer_key = 'TW-CONSUMER-KEY'.info_plist
        secret_key = 'TW-SECRET-KEY'.info_plist
        account = twitter_account
        if account && !reconnect
          STTwitterAPI.twitterAPIWithOAuthConsumerName("TwRblg",
                                                       consumerKey: consumer_key,
                                                       consumerSecret: secret_key,
                                                       oauthToken: account.oauth_token,
                                                       oauthTokenSecret: account.oauth_token_secret)
        else
          STTwitterAPI.twitterAPIWithOAuthConsumerName("TwRblg",
                                                       consumerKey: consumer_key,
                                                       consumerSecret: secret_key)
        end
      end
    if reconnect
      @twitter = twitter
    else
      @twitter ||= twitter
    end
  end

  TWITTER_ACCOUNT_KEY = "TWITTER-ACCOUNT"
  TUMBLR_ACCOUNT_KEY = "TUMBLR-ACCOUNT"

  def twitter_account= account
    @twitter_account = account
    KeyChainStore.setString(TWITTER_ACCOUNT_KEY, account.pack)
  end

  def twitter_account
    @twitter_account =
      begin
        s = KeyChainStore.fetch(TWITTER_ACCOUNT_KEY)
        TwitterAccount.unpack(s)
      end
  end

  def tumblr_account= account
    @tumblr_account = account
    KeyChainStore.setString(TUMBLR_ACCOUNT_KEY, account.pack)
  end

  def tumblr_account
    @tumblr_account =
      begin
        s = KeyChainStore.fetch(TUMBLR_ACCOUNT_KEY)
        TumblrAccount.unpack(s)
      end
  end
end
