class OutgoingMailerPreview < ActionMailer::Preview
  def initial_request
    OutgoingMailer.initial_request(info_request, outgoing_message)
  end

  def followup
    OutgoingMailer.followup(
      info_request, followup_message, nil
    )
  end

  private

  def user
    User.new(id: 1, name: 'Bob')
  end

  def public_body
    PublicBody.new(
      name: 'Public Body',
      request_email: 'body@localhost'
    )
  end

  def info_request
    InfoRequest.new(
      id: 1,
      user: user,
      title: 'A great FOI request',
      url_title: 'a_great_foi_request',
      public_body: public_body
    )
  end

  def outgoing_message
    OutgoingMessage.new(
      id: 1,
      info_request: info_request,
      message_type: 'initial_request',
      body: "Dear Public Body,\n\nPlease tell me how amazing my request is?"
    )
  end

  def followup_message
    OutgoingMessage.new(
      id: 2,
      info_request: info_request,
      message_type: 'followup',
      body: "Dear Public Body,\n\nWhere is the response to me request?",
      incoming_message_followup: incoming_message
    )
  end

  def incoming_message
    IncomingMessage.new(
      id: 1,
      info_request: info_request,
      raw_email: RawEmail.new,
      last_parsed: Time.now,
      cached_main_body_text_folded: 'We acknowledge your FOI request.'
    )
  end
end
