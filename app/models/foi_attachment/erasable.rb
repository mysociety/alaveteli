# Handles the erasure of FoiAttachment records.
module FoiAttachment::Erasable
  extend ActiveSupport::Concern

  ErasedError = Class.new(StandardError)

  included do
    scope :erased, -> { where.not(erased_at: nil) }

    delegate :erased?, :ensure_not_erased!, to: :raw_email, prefix: :raw_email
  end

  def erased?
    erased_at.present?
  end

  def ensure_not_erased!
    raise ErasedError, "attachment has been erased (ID=#{id})" if erased?
  end

  def erase_later(editor:, reason:)
    FoiAttachment::EraseJob.perform_later(self, editor: editor, reason: reason)
  end

  def erase(editor:, reason:)
    return if erased?

    mask_siblings

    transaction do |t|
      t.after_rollback { return false }

      log_event(
        'erase_attachment',
        editor: editor,
        reason: reason,
        attachment: self,
        storage_key: storage_key
      ) || raise(ActiveRecord::Rollback, 'could not log erase_attachment event')

      self.filename = nil
      ensure_filename!

      self.erased_at = Time.zone.now
      save!

      delete_cached_file!

      raw_email.erase(editor: editor, reason: 'FoiAttachment#erase')

      expire

      true
    rescue StandardError => ex
      Rails.logger.error(
        "FoiAttachment#erase failed (ID=#{id}): #{ex.class}: #{ex.message}"
      )
      raise
    end
  end
end
