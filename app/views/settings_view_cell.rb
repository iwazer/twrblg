class SettingsViewCell < UITableViewCell
  extend IB

  outlet :status

  def initWithCoder decoder
    super
  end

  def update_status s
    status.text = s.nil_then_blank
  end
end
