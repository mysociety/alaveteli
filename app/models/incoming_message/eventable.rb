# Handles relevant InfoRequestEvent records on the associated InfoRequest.
module IncomingMessage::Eventable
  extend ActiveSupport::Concern

  included do
    delegate :log_event, to: :info_request
  end

  def update_and_log_event(event: {}, **params)
    update_and_log_event!(event: event, **params)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def update_and_log_event!(event: {}, **params)
    transaction do
      update!(params)

      log_event(
        'edit_incoming',
        event.merge(
          incoming_message_id: id,
          old_prominence: prominence_previously_was,
          prominence: prominence,
          old_prominence_reason: prominence_reason_previously_was,
          prominence_reason: prominence_reason
        )
      )
    end
  end
end
