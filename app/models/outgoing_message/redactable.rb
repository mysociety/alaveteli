module OutgoingMessage::Redactable
  extend ActiveSupport::Concern

  def redacted?
    from_name_redacted? || body_redacted?
  end

  # TODO: Ideally should log an event for destructive edits
  def make_redactions_permanent
    return unless redacted?

    self.from_name = safe_from_name if from_name_redacted?
    self.body = body if body_redacted?

    save!
  end

  private

  def from_name_redacted?
    safe_from_name != from_name
  end

  def body_redacted?
    clean_text(read_attribute(:body)) != body
  end
end
