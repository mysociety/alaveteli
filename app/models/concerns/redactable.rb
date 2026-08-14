# Applies applicable TextMasks and CensorRules from the parent InfoRequest to
# attributes defined as being redactable.
module Redactable
  extend ActiveSupport::Concern

  included do
    class_attribute :redactable_attrs, default: []

    delegate :apply_masks, to: :info_request

    attr_writer :unredacted_access
  end

  class_methods do
    # Declare attributes/methods whose values may contain personal data.
    # Direct access returns redacted content; use #unredacted to access raw
    # values.
    def redactable(*attrs)
      self.redactable_attrs = attrs

      prepend(Module.new do
        attrs.each do |attr|
          define_method(attr) do |*args, **kwargs, &block|
            return_super = unredacted_access || !info_request
            return super(*args, **kwargs, &block) if return_super

            apply_masks_to(attr, *args, **kwargs, &block)
          end
        end
      end)
    end
  end

  # Returns the redacted value for attr. Dispatches to apply_masks_to_<attr>
  # if defined on the model, otherwise runs the plain text masking pipeline.
  # Any extra args/kwargs are forwarded to a custom apply_masks_to_<attr>,
  # but are not meaningful for the default masking pipeline.
  #
  # Masking needs a persisted info_request (the default pipeline calls
  # info_request.apply_masks, which masks out the request's own incoming
  # email address, and that needs an id) - so with no persisted info_request
  # to pull rules from, nothing gets masked, custom or otherwise.
  def apply_masks_to(attr, *args, **kwargs, &block)
    unless respond_to?(attr)
      msg = "Unknown method :#{attr} given to #{self.class} redactable"
      raise ArgumentError, msg
    end

    unless info_request.persisted?
      return unredacted.send(attr, *args, **kwargs, &block)
    end

    if respond_to?("apply_masks_to_#{attr}", true)
      send("apply_masks_to_#{attr}", *args, **kwargs, &block)
    else
      apply_masks(unredacted.send(attr), 'text/plain')
    end
  end

  def unredacted
    @unredacted ||= Redactable::Unredacted.new(self)
  end

  def unredacted_access
    @unredacted_access || false
  end

  # Validations (e.g. validates_presence_of) read the attribute via this
  # method, which by default just calls the public getter. For a redactable
  # attr that would run it through the masking pipeline - validating the
  # masked value instead of what's actually stored, and re-entering masking
  # (with its own side effects/failure modes) as a side effect of validating.
  def read_attribute_for_validation(attr)
    return unredacted.send(attr) if self.class.redactable_attrs.include?(attr)

    super
  end
end
