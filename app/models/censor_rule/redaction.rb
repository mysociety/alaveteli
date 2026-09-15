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
    where(redactable: info_request).
      or(where(redactable: info_request.outgoing_messages)).
      or(where(redactable: info_request.incoming_messages)).
      or(where(redactable: info_request.foi_attachments))
  }
end
