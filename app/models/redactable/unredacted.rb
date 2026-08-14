# Provides unredacted access to a Redactable's attributes
class Redactable::Unredacted < SimpleDelegator
  def method_missing(method_name, *args, **kwargs, &block)
    with_unredacted_access do
      record.public_send(method_name, *args, **kwargs, &block)
    end
  end

  def with_unredacted_access
    was = record.unredacted_access
    record.unredacted_access = true
    yield
  ensure
    record.unredacted_access = was
  end

  def class
    record.class
  end

  private

  def record
    __getobj__
  end
end
