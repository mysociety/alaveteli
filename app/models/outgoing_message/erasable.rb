module OutgoingMessage::Erasable
  extend ActiveSupport::Concern

  def erase_later(editor:, reason:)
    OutgoingMessage::ErasureJob.
      perform_later(self, editor: editor, reason: reason)
  end

  # Nullify the fields that may contain PII, and log
  # an event explaining why the message was cleared
  def erase(...)
    erase!(...)
  rescue ActiveRecord::RecordInvalid
    false
  end

  def erase!(editor:, reason:)
    transaction do
      params = {
        body: '', # body cannot be null in database
        from_name: nil,
        erased_at: Time.zone.now
      }
      update!(params)
      search_documents.delete_all
      log_event(
        'erase_outgoing',
        editor: editor,
        reason: reason,
        outgoing_message: self
      )
    end
  end
end
