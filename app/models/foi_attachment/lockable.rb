# Handles the locking of FoiAttachment files. Locking means that no further
# modifications – parsing, redacting – can be made to the attachment.
module FoiAttachment::Lockable
  extend ActiveSupport::Concern

  included do
    validate :must_be_unlockable_to_unlock, on: :update

    scope :locked, -> { where(locked: true) }
    scope :unlocked, -> { where(locked: false) }
  end

  # Note that #lock still raises on failure. This version also runs
  # pre-and-post-locking steps, whereas #lock! omits these for more flexibility
  # when composing with other actions.
  def lock(...)
    lock!(...)
    expire
    mask_later unless masked_at # TODO: want to use #mask instead of #mask_later
  end

  # Note that #unlock still raises on failure. This version also runs
  # pre-and-post-unlocking steps, whereas #unlock! omits these for more
  # flexibility when composing with other actions.
  def unlock(...)
    unlock!(...)
    expire
    mask_later unless masked_at # TODO: want to use #mask instead of #mask_later
  end

  def lock!(editor:, reason:, **event)
    return true if locked?

    update_and_log_event!(
      event: { **event, editor: editor, reason: reason },
      locked: true,
      filename: redacted_filename
    )

    true
  end

  def unlock!(editor:, reason:, **event)
    return true if unlocked?

    update_and_log_event!(
      event: { **event, editor: editor, reason: reason },
      locked: false,
      masked_at: nil
    )

    if replaced?
      file_blob.upload(StringIO.new(unmasked_body), identify: false)
      file_blob.save

      update!(
        filename: mail_attributes[:filename],
        replaced_at: nil,
        replaced_reason: nil
      )
    end

    ensure_filename!

    true
  end

  def unlocked?
    !locked?
  end

  def lockable?
    unlocked?
  end

  def unlockable?
    !incoming_message.raw_email_erased?
  end

  def locking?
    locked? && locked_changed?
  end

  def unlocking?
    !locked? && locked_changed?
  end

  private

  def must_be_unlockable_to_unlock
    return if !unlocking? || unlockable?

    errors.add(:base, 'This attachment cannot be unlocked.')
  end
end
