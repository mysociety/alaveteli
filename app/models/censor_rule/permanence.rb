# Make the redactions of a CensorRule permanent, so that the rule can then be
# erased without the redacted content becoming visible again.
#
# Relies on CensorRule::Redaction records to find the content the rule has
# redacted, so content that hasn't been rendered since redaction tracking was
# enabled won't be made permanent.
module CensorRule::Permanence
  extend ActiveSupport::Concern

  class_methods do
    # Make the rules permanent, then erase them if all succeeded.
    #
    # Content made permanent no longer contains what the rules matched, so
    # re-rendering it before the rules are erased (e.g. when reindexing) finds
    # nothing to redact and drops the record of the redaction. Restore these
    # once the rules are erased – and so can't apply again – as the record of
    # what was made permanent.
    def make_permanent_and_erase(rules, editor:)
      recorded = rules.flat_map do |rule|
        rule.redactions.map do |redaction|
          redaction.slice(:censor_rule_id, :redactable_type, :redactable_id,
                          :redacted_attribute)
        end
      end

      return false unless rules.map { _1.make_permanent(editor: editor) }.all?

      rules.each { _1.erase(editor: editor) }
      recorded.each { CensorRule::Redaction.find_or_create_by!(_1) }

      true
    end
  end

  # IncomingMessages where the rule has redacted the message itself or one of
  # its attachments
  def redacted_incoming_messages
    attachments = FoiAttachment.where(id: redacted_ids('FoiAttachment'))

    IncomingMessage.
      where(id: redacted_ids('IncomingMessage')).
      or(IncomingMessage.where(id: attachments.select(:incoming_message_id)))
  end

  def redacted_outgoing_messages
    OutgoingMessage.where(id: redacted_ids('OutgoingMessage'))
  end

  # Attachments are locked with all applicable rules applied, as we can't
  # selectively mask with only this rule. Outgoing messages are stored in our
  # database, so only this rule needs to be applied.
  #
  # Redactions of InfoRequest#from_name aren't made permanent as it is derived
  # from the outgoing messages and the User.
  def make_permanent(editor:, reason: 'CensorRule#make_permanent')
    incoming = redacted_incoming_messages.find_each.map do |message|
      message.make_redactions_permanent(editor: editor, reason: reason)
    end

    outgoing = redacted_outgoing_messages.find_each.map do |message|
      message.make_redactions_permanent(self, editor: editor, reason: reason)
    end

    (incoming + outgoing).all?
  end

  private

  def redacted_ids(redactable_type)
    redactions.where(redactable_type: redactable_type).select(:redactable_id)
  end
end
