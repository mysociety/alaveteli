module OutgoingMessage::Redactable
  extend ActiveSupport::Concern

  def redacted?
    from_name_redacted? || body_redacted?
  end

  def make_redactions_permanent(editor:, reason: 'OutgoingMessage#make_redactions_permanent')
    return unless redacted?

    self.from_name = safe_from_name if from_name_redacted?
    self.body = body if body_redacted?
    save!

    log_event(
      'edit_outgoing',
      editor: editor,
      reason: reason,
      outgoing_message_id: id,
      body_changed: body_previously_changed?,
      from_name_changed: from_name_previously_changed?
    )
  end

  private

  def from_name_redacted?
    safe_from_name != from_name
  end

  def body_redacted?
    clean_text(read_attribute(:body)) != body
  end
end
