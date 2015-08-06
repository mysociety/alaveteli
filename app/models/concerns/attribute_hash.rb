module AttributeHash

  extend ActiveSupport::Concern

  def attribute_hash(attributes, key_prefix = nil)
    items = attributes.collect do |attribute|
      key = key_prefix ? "#{key_prefix}_#{attribute}".to_sym : attribute
      [key, send(attribute)]
    end
    Hash[items]
  end

end
