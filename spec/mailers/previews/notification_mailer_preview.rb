class NotificationMailerPreview < ActionMailer::Preview
  def daily_summary
    NotificationMailer.daily_summary(user, notifications)
  end

  private

  def user
    User.new(
      name: 'Pro user',
      email: 'pro@localhost'
    )
  end

  # 902: useless_incoming_message_event
  def notifications
    [
      Notification.new(user: user, info_request_event: InfoRequestEvent.find(902))
    ]
  end
end
