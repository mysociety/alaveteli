# Handles the locking of FoiAttachment files. Locking means that no further
# modifications – parsing, redacting – can be made to the attachment.
module FoiAttachment::Lockable
  extend ActiveSupport::Concern

  included do
    before_save :handle_locked

    scope :locked, -> { where(locked: true) }
    scope :unlocked, -> { where(locked: false) }
  end

  # Note that #lock still raises on failure. This version also runs
  # pre-and-post-locking steps, whereas #lock! omits these for more flexibility
  # when composing with other actions.
  def lock(...)
    lock!(...)
    expire
  end

  # Note that #unlock still raises on failure. This version also runs
  # pre-and-post-unlocking steps, whereas #unlock! omits these for more
  # flexibility when composing with other actions.
  def unlock(...)
    unlock!(...)
    expire
  end

  def lock!(editor:, reason:, **event)
    return true if locked?

    update_and_log_event!(
      event: { **event, editor: editor, reason: reason },
      locked: true,
      filename: redacted_filename
    )

    #if locking?
      #self.filename = redacted_filename
    #end

    mask_later unless masked_at

    true
  end

  def unlock!(editor:, reason:, **event)
    return true if unlocked?

    update_and_log_event!(
      event: { **event, editor: editor, reason: reason },
      locked: false
    )

    #if unlocking? && replaced?
    if replaced?
      file_blob.upload(StringIO.new(unmasked_body), identify: false)
      file_blob.save

      self.replaced_at = nil
      self.replaced_reason = nil
    end

    #if unlocking?
      self.masked_at = nil
      self.filename = mail_attributes[:filename]
      ensure_filename!
    #end

    mask_later unless masked_at

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
    true
  end
end
