module OutgoingMessage::Redactable
  extend ActiveSupport::Concern

  def redacted?
    from_name_redacted? || body_redacted?
  end

  private

  def from_name_redacted?
    safe_from_name != from_name
  end

  def body_redacted?
    clean_text(read_attribute(:body)) != body
  end
end
