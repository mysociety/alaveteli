class TrackMailerPreview < ActionMailer::Preview
  def event_digest
    TrackMailer.event_digest(user, email_about_things)
  end

  private

  def user
    User.new(id: 1, name: 'Bob', url_name: 'bob', email: 'bob@localhost')
  end

  def email_about_things
    [
      [
        track_thing,
        [
          OpenStruct.new(model: comment_event),
          OpenStruct.new(model: response_event),
          OpenStruct.new(model: followup_sent),
          OpenStruct.new(model: sent_event)
        ],
        ActsAsXapian::Search.new([InfoRequestEvent], 'matches', limit: 10)
      ]
    ]
  end

  def track_thing
    OpenStruct.new(
      params: {
        title_in_email: 'Requests or responses matching your saved search'
      }
    )
  end

  def other_user
    User.new(id: 2, name: 'Alice')
  end

  def public_body
    PublicBody.new(name: 'Ministry of Silly Walks')
  end

  def info_request
    InfoRequest.new(
      user: other_user,
      title: 'A great FOI request',
      url_title: 'a_great_foi_request',
      public_body: public_body
    )
  end

  def outgoing_message
    OutgoingMessage.new(
      id: 1,
      info_request: info_request
    )
  end

  def sent_event
    InfoRequestEvent.new(
      info_request: info_request,
      outgoing_message: outgoing_message,
      event_type: 'sent',
      created_at: Time.now
    )
  end

  def followup_sent
    InfoRequestEvent.new(
      info_request: info_request,
      outgoing_message: outgoing_message,
      event_type: 'followup_sent',
      created_at: Time.now
    )
  end

  def incoming_message
    IncomingMessage.new(
      id: 1,
      info_request: info_request,
      cached_attachment_text_clipped: '',
      cached_main_body_text_folded: 'This body matches the search term'
    )
  end

  def response_event
    InfoRequestEvent.new(
      info_request: info_request,
      incoming_message: incoming_message,
      event_type: 'response',
      created_at: Time.now
    )
  end

  def comment
    Comment.new(
      id: 1,
      info_request: info_request,
      user: other_user,
      body: 'An insightful comment'
    )
  end

  def comment_event
    InfoRequestEvent.new(
      info_request: info_request,
      comment: comment,
      event_type: 'comment',
      created_at: Time.now
    )
  end
end
