# Handles the locking of FoiAttachment files. Locking means that no further
# modifications – parsing, redacting – can be made to the attachment.
module FoiAttachment::Lockable
  extend ActiveSupport::Concern

  included do
    before_save :handle_locked

    scope :locked, -> { where(locked: true) }
    scope :unlocked, -> { where(locked: false) }
  end

  def lock!(editor:, reason:, **event)
    return true if locked?

    return false unless update_and_log_event(
      event: { **event, editor: editor, reason: reason },
      locked: true
    )

    true
  end

  def unlocked?
    !locked?
  end

  def locking?
    locked? && locked_changed?
  end

  def unlocking?
    !locked? && locked_changed?
  end

  private

  def handle_locked
    if unlocking? && replaced?
      file_blob.upload(StringIO.new(unmasked_body), identify: false)
      file_blob.save

      self.replaced_at = nil
      self.replaced_reason = nil
    end

    if unlocking?
      self.masked_at = nil
      self.filename = mail_attributes[:filename]
      ensure_filename!
    end

    self.filename = redacted_filename if locking?

    if locking? || unlocking?
      mask_later unless masked_at
    end

    true
  end
end
