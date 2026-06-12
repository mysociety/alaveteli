module Redactable
  extend ActiveSupport::Concern

  included do
    class_attribute :redactable_attrs, default: []

    delegate :apply_masks, to: :info_request
  end

  class_methods do
    # Allow classes to set attributes or methods that may contain personal data
    # and so should be put through the redaction pipeline to check for any
    # applicable redactions.
    def redactable(*attrs)
      self.redactable_attrs = attrs
    end
  end

  def redacted
    @redacted ||= Redacted.new(self)
  end

  end
end
