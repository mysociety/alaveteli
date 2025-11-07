# Cache attributes from the associated RawEmail before calling the attribute's
# accessor
module IncomingMessage::CacheAttributesFromRawEmail
  extend ActiveSupport::Concern

  class_methods do
    def cache_from_raw_email(*attrs)
      attrs.each { |attr| cache_attribute_from_raw_email(attr) }
    end

    def cache_attribute_from_raw_email(attr)
      define_method(attr) do
        parse_raw_email!
        super()
      end
    end
  end
end
