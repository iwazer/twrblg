class SettingsViewCell < UITableViewCell
  extend IB

  outlet :status

  def initWithCoder decoder
    super
  end

  def update_status account
    @default_value ||= status.text
    status.text = account.nil? ? @default_value : account.screen_name
  end
end
