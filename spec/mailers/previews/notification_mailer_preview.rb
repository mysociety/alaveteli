class NotificationMailerPreview < ActionMailer::Preview
  def daily_summary
    NotificationMailer.daily_summary(
      user, [
        notification('embargo_expiring'),
        notification('expire_embargo'),
        notification('overdue'),
        notification('response'),
        notification('very_overdue'),
        batch_notification('embargo_expiring'),
        batch_notification('expire_embargo'),
        batch_notification('overdue'),
        batch_notification('response'),
        batch_notification('very_overdue')
      ]
    )
  end

  def response_notification
    NotificationMailer.response_notification(notification)
  end

  def embargo_expiring_notification
    NotificationMailer.embargo_expiring_notification(notification)
  end

  def expire_embargo_notification
    NotificationMailer.expire_embargo_notification(notification)
  end

  def overdue_notification
    NotificationMailer.overdue_notification(notification)
  end

  def very_overdue_notification
    NotificationMailer.very_overdue_notification(notification)
  end

  private

  def notification(type = 'response')
    Notification.new(
      user: user,
      info_request_event: InfoRequestEvent.new(
        event_type: type,
        info_request: info_request,
        incoming_message: incoming_message
      )
    )
  end

  def info_request
    InfoRequest.new(
      title: 'A request',
      url_title: 'a_request',
      user: User.first,
      public_body: PublicBody.first,
      described_state: 'successful'
    )
  end

  def user
    info_request.user
  end

  def incoming_message
    IncomingMessage.new(
      id: 123,
      info_request: info_request,
      raw_email: RawEmail.new,
      last_parsed: Time.now,
      sent_at: Time.now
    )
  end

  def batch_notification(type = 'response')
    Notification.new(
      user: user,
      info_request_event: InfoRequestEvent.new(
        event_type: type,
        info_request: batched_info_request,
        incoming_message: incoming_message
      )
    )
  end

  def batched_info_request
    info_request.tap do |info_request|
      info_request.title = 'Batch request'
      info_request.url_title = 'batched_request'
      info_request.info_request_batch_id = 456
      info_request.info_request_batch = InfoRequestBatch.new(
        id: 456,
        title: 'Batch request'
      )
    end
  end
end
