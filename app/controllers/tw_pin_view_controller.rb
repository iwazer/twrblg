class TwPinViewController < UIViewController
  attr_writer :url, :callback_at_poped

  def viewDidLoad
    @web_view = UIWebView.new
    @web_view.scalesPageToFit = true
    @web_view.delegate = self
    self.view = @web_view
    req = NSURLRequest.requestWithURL @url
    @web_view.loadRequest req
  end

  ### WebView Delegater

  def webViewDidFinishLoad webView
    pin_code = get_pin_code
    if pin_code.present?
      twitter = App.shared.delegate.twitter
      successBlock = -> (oauthToken,oauthTokenSecret,userID,screenName) {
        account = TwitterAccount.new(userID, oauthToken, oauthTokenSecret, screenName)
        App.shared.delegate.twitter_account = account
        @callback_at_poped.call(account)
      }
      twitter.postAccessTokenRequestWithPIN(pin_code,
                                            successBlock: successBlock,
                                            errorBlock: lambda {|error|
                                              App.alert(error.localizedDescription)
                                            })
      self.navigationController.popViewControllerAnimated(true)
    end
  end

  def get_pin_code
    js = "document.getElementsByTagName('code')[0].innerText"
    @web_view.stringByEvaluatingJavaScriptFromString(js)
  end

  def current_url
    webView.stringByEvaluatingJavaScriptFromString("window.location")
  end

  def document_title
    web_view.stringByEvaluatingJavaScriptFromString("document.title")
  end
end
