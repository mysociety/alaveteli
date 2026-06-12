class Redactable::Unredacted < SimpleDelegator
  def method_missing(method_name, *args, **kwargs, &block)
    if record.redactable_attrs.include?(method_name)
      with_unredacted_access { record.public_send(method_name) }
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    record.redactable_attrs.include?(method_name) || super
  end

  def with_unredacted_access
    was = record.unredacted_access
    record.unredacted_access = true
    yield(self)
  ensure
    record.unredacted_access = was
  end

  private

  def record
    __getobj__
  end
end
