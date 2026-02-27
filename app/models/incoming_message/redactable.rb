module IncomingMessage::Redactable
  extend ActiveSupport::Concern

  def redacted?
    from_name_redacted? ||
      cached_main_body_redacted? ||
      attachments_redacted?
  end

  def make_redactions_permanent
    return unless redacted?

    # FIXME: Need to pass through the params; going to explore Current for this.
    event_params = {
      editor: User.with_role(:admin).last,
      reason: 'IncomingMessage#make_redactions_permanent'
    }

    # Commit cached attribute redactions
    # TODO: In future we should ensure all cached attributes can be redacted.
    # Currently some aren't (e.g. from_email)
    update!(from_name: safe_from_name)

    # Commit attachment redactions
    clear_in_database_caches! # These get regenerated from the locked attachment
    lock_all_attachments(**event_params)
    foi_attachments.each(&:mask)
    raw_email.erase(**event_params) unless raw_email.erased?
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
