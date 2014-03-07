# -*- coding: utf-8 -*-
class TbrPostViewController < UIViewController
  extend IB

  attr_writer :status

  outlet :postTextView, UITextView
  outlet :postImageView, UIImageView
  outlet :postBlogLabel, UILabel

  def viewDidLoad
    @inputAccessoryView = XCDFormInputAccessoryView.new
    navigationItem.setRightBarButtonItem(nil, animated:true)
    setup_spinner(@postImageView)
    #Dispatch::Queue.concurrent.async {
      start_activity_indicator
      image = @status.image_url.nsurl.fetch_image
      #Dispatch::Queue.main.async {
        postImageView.image = image
        stop_activity_indicator
      #}
    #}
    @account = App.shared.delegate.tumblr_account
    @postBlogLabel.text = @account.blog.try(:name)
    self.postTextView.text = @status.text
  end

  def viewWillAppear animated
    super

    unless @registered
      center = NSNotificationCenter.defaultCenter
      center.addObserver(self,
                         selector: "keyboardWillShow:",
                         name: UIKeyboardWillShowNotification,
                         object: nil)
      center.addObserver(self,
                         selector: "keybaordWillHide:",
                         name: UIKeyboardWillHideNotification,
                         object: nil)
    end
  end

  def viewWillDisappear animated
    super

    if @registered
      center = NSNotificationCenter.defaultCenter
      center.removeObserver(self,
                            name: UIKeyboardWillShowNotification,
                            object: nil)
      center.removeObserver(self,
                            name: UIKeyboardWillHideNotification,
                            object: nil)
      @registered = false
    end
  end

  def keyboardWillShow notification
    offset = view.contentOffset
    offset.y = offset.y += 210

    userInfo = notification.userInfo
    duration = userInfo[UIKeyboardAnimationDurationUserInfoKey].to_f
    animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey].to_i
    animations = -> {
      view.contentOffset = offset
    }
    UIView.animateWithDuration(duration,
                               delay: 0.0,
                               options: animationCurve << 16,
                               animations: animations,
                               completion: nil)
  end

  def keybaordWillHide notification
    offset = view.contentOffset
    offset.y -= 210
    userInfo = notification.userInfo
    duration = userInfo[UIKeyboardAnimationDurationUserInfoKey].to_f
    animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey].to_i
    animations = -> {
      view.contentOffset = offset
    }
    UIView.animateWithDuration(duration,
                               delay: 0.0,
                               options: animationCurve << 16,
                               animations: animations,
                               completion:nil)
  end

  def delete_text sender
    @postTextView.text = ""
    @postTextView.setNeedsDisplay
  end

  def reblog sender
    link = @status.link
    source = @status.image_url
    parameters = {"caption" => self.postTextView.text,
      "link" => link,
      "source" => source
    }
    callback = -> (resp,error) {
      if error
        App.alert("エラーが発生しました: #{error.localizedDescription}")
      end
    }
    name = @account.blogs[@account.default_blog_index].try(:name)
    TMAPIClient.sharedInstance.photo(name,
                                     filePathArray: nil,
                                     contentTypeArray: nil,
                                     fileNameArray: nil,
                                     parameters: parameters,
                                     callback: callback)
  end

  def inputAccessoryView
    @inputAccessoryView
  end

  def blog_label_tapped
    @action_sheet ||=
      begin
        sheet = UIActionSheet.alloc.initWithTitle(nil,
                                                  delegate: nil,
                                                  cancelButtonTitle: "cancel",
                                                  destructiveButtonTitle: nil,
                                                  otherButtonTitles: nil)

        pickerView = UIPickerView.alloc.initWithFrame([[0, 0], [0, 0]])
        pickerView.showsSelectionIndicator = true
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(@account.default_blog_index||0,
                             inComponent: 0,
                             animated: false)
        sheet.addSubview(pickerView)
        sheet
      end
    @action_sheet.showInView(view)
    @action_sheet.setBounds([[0, 0], [320, 415]])
  end

  def image_tapped
    if @orig_image_frame
      UIView.animateWithDuration(0.2, animations: -> {
                                   @postImageView.frame = [[160,240], [0,0]]
                                 }, completion: -> (finished) {
                                   @postImageView.frame = @orig_image_frame
                                   @orig_image_frame = nil
                                   postTextView.hidden = false
                                   postBlogLabel.hidden = false
                                   navigationController.navigationBarHidden = false
                                   navigationController.toolbarHidden = false
                                 })
    else
      postTextView.hidden = true
      postBlogLabel.hidden = true
      navigationController.navigationBarHidden = true
      navigationController.toolbarHidden = true
      @orig_image_frame = @postImageView.frame
      @postImageView.frame = [[160,240], [0,0]]
      UIView.animateWithDuration(0.2, animations: -> {
                                   @postImageView.frame = UIScreen.mainScreen.bounds
                                 })
    end
  end

  def numberOfComponentsInPickerView pickerView
    1
  end

  def pickerView pickerView, numberOfRowsInComponent: componen
    @account.blogs.try(:count) || 0
  end

  def pickerView pickerView, titleForRow: row, forComponent: component
    @account.blogs[row].title
  end

  def pickerView pickerView, didSelectRow: row, inComponent: component
    @account.default_blog_index = row
    @postBlogLabel.text = @account.blogs[row].title
    App.shared.delegate.tumblr_account = @account
    @action_sheet.dismissWithClickedButtonIndex(0, animated: true)
    navigationItem.setRightBarButtonItem(nil, animated:true)
  end

  include Spinner
end
