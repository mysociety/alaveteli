# Handles the erasure of RawEmail records.
module RawEmail::Erasable
  extend ActiveSupport::Concern

  class ErasedError < StandardError; end

  included do
    delegate :all_attachments_masked_or_erased?, to: :incoming_message
  end

  def erased?
    !file.attached? && erased_at.present?
  end

  def ensure_not_erased!
    raise ErasedError, "email has been erased (ID=#{id})" if erased?
  end

  def erasable?
    all_attachments_masked_or_erased?
  end

  def erase(editor:, reason:)
    return if erased?

    raise RawEmail::UnmaskedAttachmentsError unless erasable?

    transaction do |t|
      t.after_rollback { return false }

      lock_all_attachments(
        editor: editor,
        reason: 'RawEmail#erase',
        raw_email: self
      ) || raise(ActiveRecord::Rollback, 'could not lock all attachments')

      log_event(
        'erase_raw_email',
        editor: editor,
        reason: reason,
        raw_email: self,
        storage_key: storage_key
      ) || raise(ActiveRecord::Rollback, 'could not log erase_raw_email event')

      file.purge_later
      inbound_email&.destroy
      touch(:erased_at)

      expire(preserve_database_cache: true)

      true
    rescue StandardError => ex
      Rails.logger.error(
        "RawEmail#erase failed (ID=#{id}): #{ex.class}: #{ex.message}"
      )
      raise
    end
  end
end
