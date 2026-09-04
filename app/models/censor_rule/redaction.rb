# == Schema Information
#
# Table name: censor_rule_redactions
#
#  id                 :bigint           not null, primary key
#  censor_rule_id     :bigint           not null
#  redactable_type    :string           not null
#  redactable_id      :bigint           not null
#  redacted_attribute :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class CensorRule::Redaction < ApplicationRecord
  belongs_to :censor_rule
  belongs_to :redactable, polymorphic: true

  validates_presence_of :redacted_attribute

  scope :for_request, ->(info_request) {
    outgoing = where(
      redactable_type: 'OutgoingMessage',
      redactable_id: info_request.outgoing_messages.select(:id)
    )
    incoming = where(
      redactable_type: 'IncomingMessage',
      redactable_id: info_request.incoming_messages.select(:id)
    )
    attachments = where(
      redactable_type: 'FoiAttachment',
      redactable_id: FoiAttachment.where(
        incoming_message_id: info_request.incoming_messages.select(:id)
      ).select(:id)
    )
    info_request_self = where(
      redactable_type: 'InfoRequest',
      redactable_id: info_request.id
    )

    outgoing.or(incoming).or(attachments).or(info_request_self)
  }
end
