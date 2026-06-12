class Redactable::Redacted < SimpleDelegator
  def method_missing(method_name, *args, **kwargs, &block)
    if record.redactable_attrs.include?(method_name)
      apply_masks_to(method_name)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    record.redactable_attrs.include?(method_name) || super
  end

  # Allow classes to define a custom masking method per attribute. If a custom
  # method is not defined, its assumed the attribute can be redacted by the
  # plain text pipeline.
  def apply_masks_to(attr)
    if record.respond_to?("apply_masks_to_#{attr}")
      record.send("apply_masks_to_#{attr}")
    elsif record.respond_to?(attr)
      record.apply_masks(record.public_send(attr).to_s, 'text/plain')
    else
      msg = "Unknown method :#{attr} given to #{record.class} redactable"
      raise ArgumentError, msg
    end
  end

  private

  def record
    __getobj__
  end
end
