# Fix the current redactions of an IncomingMessage in place, so that they
# persist even if the CensorRules that made them are later changed or erased.
#
# Attachments are masked with the current rules and locked, and the RawEmail is
# erased so that we no longer hold the original, unredacted content.
module IncomingMessage::PermanentRedactions
  extend ActiveSupport::Concern

  def make_redactions_permanent(editor:, reason:)
    return true if raw_email_erased?

    # Re-mask so that the attachments are locked with the current rules
    # applied, rather than whatever was in effect when last masked
    foi_attachments.unlocked.not_erased.each(&:mask)

    # Commit cached attribute redactions as these are read from the database
    # rather than re-derived from the RawEmail.
    # TODO: Not all cached attributes are redacted (e.g. from_email)
    update!(from_name: safe_from_name)

    log_event(
      'edit_incoming',
      editor: editor,
      reason: reason,
      incoming_message_id: id,
      from_name_changed: from_name_previously_changed?
    )

    # These get regenerated from the locked attachments
    clear_in_database_caches!

    # Locks all attachments before erasing
    raw_email.erase(editor: editor, reason: reason)
  end
end
