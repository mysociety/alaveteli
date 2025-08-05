class RequestMailer::NewResponsePreview < ActionMailer::Preview
  def public
    RequestMailer.new_response(info_request, incoming_message)
  end

  def embargoed
    RequestMailer.new_response(info_request_with_embargo, incoming_message)
  end

  private

  def info_request
    InfoRequest.new(
      title: 'A request',
      url_title: 'a_request',
      user: User.first,
      public_body: PublicBody.first
    )
  end

  def info_request_with_embargo
    info_request.tap do |info_request|
      info_request.embargo = AlaveteliPro::Embargo.new
    end
  end

  def incoming_message
    IncomingMessage.new(
      id: 123,
      info_request: info_request
    )
  end
end
