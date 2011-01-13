# override behaviour in fast_gettext/translation.rb
# so that we can interpolate our translation strings nicely

def _(key, options = {})
  translation = FastGettext._(key) || key
  gettext_interpolate(translation, options)
end

INTERPOLATION_RESERVED_KEYS = %w(scope default)
MATCH = /(\\\\)?\{\{([^\}]+)\}\}/

def gettext_interpolate(string, values)
  return string unless string.is_a?(String)
  if values.is_a?(Hash)
    string.gsub(MATCH) do
      escaped, pattern, key = $1, $2, $2.to_sym
      
      if escaped
        pattern
      elsif INTERPOLATION_RESERVED_KEYS.include?(pattern)
        raise ReservedInterpolationKey.new(pattern, string)
      elsif !values.include?(key)
        raise MissingInterpolationArgument.new(pattern, string)
      else
        values[key].to_s
      end
    end
  else
    reserved_keys = if defined?(I18n::RESERVED_KEYS) # rails 3+
                      I18n::RESERVED_KEYS
                    else
                      I18n::Backend::Base::RESERVED_KEYS
                    end

    string % values.except(*reserved_keys)
  end
end
