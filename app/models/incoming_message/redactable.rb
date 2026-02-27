module IncomingMessage::Redactable
  extend ActiveSupport::Concern

  def redacted?
    from_name_redacted? ||
      cached_main_body_redacted? ||
      attachments_redacted?
  end

  def make_redactions_permanent(editor:, reason: 'IncomingMessage#make_redactions_permanent')
    return unless redacted?

    raise RawEmail::UnmaskedAttachmentsError unless all_attachments_masked?

    # Commit cached attribute redactions
    # TODO: In future we should ensure all cached attributes can be redacted.
    # Currently some aren't (e.g. from_email)
    update!(from_name: safe_from_name)

    log_event(
      'edit_incoming',
      editor: editor,
      reason: reason,
      incoming_message_id: id,
      from_name_changed: from_name_previously_changed?
    )

    # Commit attachment redactions
    clear_in_database_caches! # These get regenerated from the locked attachment
    lock_all_attachments(editor: editor, reason: reason)
    raw_email.erase(editor: editor, reason: reason) unless raw_email.erased?
  end

  private

  def from_name_redacted?
    safe_from_name != from_name
  end

  def cached_main_body_redacted?
    # Compare raw extracted main body text without formatting changes to that
    # text with the text masks and any censor rules applied.
    text = get_main_body_text_internal
    apply_masks(text, 'text/html') != text
  end

  def attachments_redacted?
    foi_attachments.any?(&:redacted?)
  end
end
