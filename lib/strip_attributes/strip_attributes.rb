# -*- encoding : utf-8 -*-
module StripAttributes
  # Strips whitespace from model fields and leaves nil values as nil.
  # TODO: this differs from official StripAttributes, as it doesn't make blank cells null.
  def strip_attributes!(options = nil)
    before_validation do |record|
      attribute_names = StripAttributes.narrow(record.attribute_names, options)

      attribute_names.each do |attribute_name|
        value = record[attribute_name]
        if value.respond_to?(:strip)
          stripped = value.strip
          if stripped != value
            record[attribute_name] = (value.nil?) ? nil : stripped
          end
        end
      end
    end
  end

  # Necessary because Rails has removed the narrowing of attributes using :only
  # and :except on Base#attributes
  def self.narrow(attribute_names, options)
    if options.nil?
      attribute_names
    else
      if except = options[:except]
        except = Array(except).collect { |attribute| attribute.to_s }
        attribute_names - except
      elsif only = options[:only]
        only = Array(only).collect { |attribute| attribute.to_s }
        attribute_names & only
      else
        raise ArgumentError, "Options does not specify :except or :only (#{options.keys.inspect})"
      end
    end
  end
end
