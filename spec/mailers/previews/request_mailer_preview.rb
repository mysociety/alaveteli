class RequestMailerPreview < ActionMailer::Preview
  def overdue_alert
    RequestMailer.overdue_alert(info_request, user)
  end

  def very_overdue_alert
    RequestMailer.very_overdue_alert(info_request, user)
  end

  def new_response_reminder_alert
    RequestMailer.new_response_reminder_alert(info_request, incoming_message)
  end

  def not_clarified_alert
    RequestMailer.not_clarified_alert(info_request, incoming_message)
  end

  def comment_on_alert
    RequestMailer.comment_on_alert(info_request, comment)
  end

  def comment_on_alert_plural
    RequestMailer.comment_on_alert_plural(info_request, 2, comment)
  end

  def new_response_public
    RequestMailer.new_response(info_request, incoming_message)
  end

  def new_response_embargoed
    RequestMailer.new_response(info_request_with_embargo, incoming_message)
  end

  private

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

  def another_user
    User.find(6)
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

  def comment
    Comment.new(
      id: 1,
      info_request: info_request,
      user: another_user
    )
  end

  def info_request_with_embargo
    info_request.tap do |info_request|
      info_request.embargo = AlaveteliPro::Embargo.new
    end
  end
end
