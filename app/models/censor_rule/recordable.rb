# Record when a CensorRule has actually been applied to a Redactable
module CensorRule::Recordable
  extend ActiveSupport::Concern

  PATTERN_COLUMNS = %w[text regexp case_sensitive ignore_diacritics].freeze

  included do
    has_many :redactions,
             class_name: 'CensorRule::Redaction',
             dependent: :delete_all

    before_update :clear_redactions_if_pattern_changed
  end

  private

  def record_redaction(redactable, redacted_attribute, before:, after:)
    return unless redactable&.persisted?

    if redacted_attribute.blank?
      raise ArgumentError,
            'redacted_attribute is required when redactable is given'
    end

    attributes = {
      redactable: redactable,
      redacted_attribute: redacted_attribute
    }

    if before == after
      redactions.where(attributes).delete_all
    else
      redactions.create_or_find_by!(attributes)
    end
  end

  def clear_redactions_if_pattern_changed
    redactions.delete_all if (changed & PATTERN_COLUMNS).any?
  end
end
