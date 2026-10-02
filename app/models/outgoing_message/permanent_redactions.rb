# Fix the redactions a CensorRule has made to an OutgoingMessage in place, so
# that they persist even if the rule is later changed or erased.
module OutgoingMessage::PermanentRedactions
  extend ActiveSupport::Concern

  def make_redactions_permanent(censor_rule, editor:, reason:)
    self.body = body(censor_rules: [censor_rule])
    # Read the column directly as #from_name falls back to the User's name
    self.from_name = censor_rule.apply_to_text(self[:from_name])
    return true unless changed?

    # Skip validations as historic messages may not pass the checks we make on
    # new messages, e.g. that the body has a signature
    save!(validate: false)

    log_event(
      'edit_outgoing',
      editor: editor,
      reason: reason,
      outgoing_message_id: id,
      body_changed: body_previously_changed?,
      from_name_changed: from_name_previously_changed?
    )

    true
  end
end
