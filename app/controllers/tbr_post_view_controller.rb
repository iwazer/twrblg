# -*- coding: utf-8 -*-
class TbrPostViewController < UIViewController
  extend IB

  attr_writer :status, :image

  outlet :postTextView, UITextView
  outlet :postImageView, UIImageView
  outlet :postBlogPickerView, UIPickerView

  def viewDidLoad
    @inputAccessoryView = XCDFormInputAccessoryView.new
    postImageView.image = @image
    @account = App.shared.delegate.tumblr_account
    self.postTextView.text = @status["text"]
  end

  def reblog sender
    media = @status["entities"]["media"].first
    source = "#{media["media_url"]}:large"
    parameters = {"caption" => self.postTextView.text,
      "link" => media["expanded_url"],
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
    App.shared.delegate.tumblr_account = @account
  end
end
