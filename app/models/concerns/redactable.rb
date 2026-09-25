# Shared behaviour for records that can be redacted by CensorRule
module Redactable
  extend ActiveSupport::Concern

  included do
    has_many :censor_rule_redactions,
             as: :redactable,
             class_name: 'CensorRule::Redaction',
             dependent: :delete_all
  end
end
