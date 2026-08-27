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

  # Redactions that can be worked out again by re-applying the rule. Locking
  # an attachment masks it a final time and stops any further rules being
  # applied to it, so what it redacted can no longer be recalculated.
  scope :recalculable, -> { where.not(redactable: FoiAttachment.locked) }

  scope :for_request, ->(info_request) {
    where(redactable: info_request).
      or(where(redactable: info_request.outgoing_messages)).
      or(where(redactable: info_request.incoming_messages)).
      or(where(redactable: info_request.foi_attachments))
  }
end
