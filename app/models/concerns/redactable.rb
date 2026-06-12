module Redactable
  extend ActiveSupport::Concern

  UnredactedAccessError = Class.new(StandardError)

  included do
    class_attribute :redactable_attrs, default: []

    delegate :apply_masks, to: :info_request

    attr_writer :unredacted_access
  end

  class_methods do
    # Allow classes to set attributes or methods that may contain personal data
    # and so should be put through the redaction pipeline to check for any
    # applicable redactions.
    def redactable(*attrs)
      self.redactable_attrs = attrs

      # Raise an error if a redactable attribute is accessed without first
      # explicitly allowing access by setting unredacted_access. We need to
      # prepend a module so that this override sits above any defined methods
      # in the including class.
      prepend(Module.new do
        attrs.each do |attr|
          define_method(attr) do
            raise Redactable::UnredactedAccessError unless unredacted_access
            super()
          end
        end
      end)
    end
  end

  def redacted
    @redacted ||= Redacted.new(self)
  end

  def unredacted
    @unredacted ||= Unredacted.new(self)
  end

  def unredacted_access
    @unredacted_access || Redactable::Current.unredacted_access || false
  end
end
