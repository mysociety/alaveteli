module StripAttributes
  # Strips whitespace from model fields and leaves nil values as nil.
  # XXX this differs from official StripAttributes, as it doesn't make blank cells null.
  def strip_attributes!(options = nil)
    before_validation do |record|
      attributes = StripAttributes.narrow(record.attributes, options)
      attributes.each do |attr, value|
        if value.respond_to?(:strip)
          record[attr] = (value.nil?) ? nil : value.strip
        end
      end
    end
  end
  
  # Necessary because Rails has removed the narrowing of attributes using :only
  # and :except on Base#attributes
  def self.narrow(attributes, options)
    if options.nil?
      attributes
    else
      if except = options[:except]
        except = Array(except).collect { |attribute| attribute.to_s }
        attributes.except(*except)
      elsif only = options[:only]
        only = Array(only).collect { |attribute| attribute.to_s }
        attributes.slice(*only)
      else
        raise ArgumentError, "Options does not specify :except or :only (#{options.keys.inspect})"
      end    
    end
  end
end
