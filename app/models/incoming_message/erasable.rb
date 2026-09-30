module IncomingMessage::Erasable
  extend ActiveSupport::Concern

  def erase_later(editor:, reason:)
    IncomingMessage::EraseJob.perform_later(
      self,
      editor: editor,
      reason: reason
    )
  end

  def erased?
    erased_at.present?
  end

  # erasing is potentially slow, prefer erase_later if possible
  def erase(...)
    erase!(...)
  rescue ActiveRecord::RecordInvalid
    false
  end

  def erase!(editor:, reason:)
    return if erased?

    transaction do
      update!(
        from_email: nil,
        from_name: nil,
        from_email_domain: nil,
        cached_attachment_text_clipped: nil,
        cached_main_body_text_unfolded: nil,
        cached_main_body_text_folded: nil,
        subject: nil,
        erased_at: Time.zone.now
      )
      search_documents.delete_all

      # the raw_email can't be erased before foi_attachments
      # if they are not masked, simply mark them as masked without doing
      # the actual work, since we are about to get rid of them.
      # This also minimises the risk of failure inside the transaction
      # that will rollback in case something goes wrong anyway
      foi_attachments.unmasked.map { |fa| fa.update(masked_at: Time.zone.now) }

      foi_attachments.map { |fa| fa.erase!(editor: editor, reason: reason) }

      raw_email.erase(editor: editor, reason: 'IncomingMessage#erase')

      raise ActiveRecord::Rollback unless
        log_event(
          'erase_incoming',
          editor: editor,
          reason: reason,
          incoming_message: self
        )
    end
  end
end
