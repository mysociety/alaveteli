module GettextI18nRails
  #translates i18n calls to gettext calls
  class Backend
    @@translate_defaults = true
    cattr_accessor :translate_defaults
    attr_accessor :backend

    def initialize(*args)
      self.backend = I18n::Backend::Simple.new(*args)
    end

    def available_locales
      FastGettext.available_locales || []
    end

    def translate(locale, key, options)
      if gettext_key = gettext_key(key, options)
        translation = FastGettext._(gettext_key)
        interpolate(translation, options)
      else
        backend.translate locale, key, options
      end
    end

    def method_missing(method, *args)
      backend.send(method, *args)
    end

    protected

    def gettext_key(key, options)
      flat_key = flatten_key key, options
      if FastGettext.key_exist?(flat_key)
        flat_key
      elsif self.class.translate_defaults
        [*options[:default]].each do |default|
          #try the scoped(more specific) key first e.g. 'activerecord.errors.my custom message'
          flat_key = flatten_key default, options
          return flat_key if FastGettext.key_exist?(flat_key)

          #try the short key thereafter e.g. 'my custom message'
          return default if FastGettext.key_exist?(default)
        end
        return nil
      end
    end

    def interpolate(string, values)
      reserved_keys = if defined?(I18n::RESERVED_KEYS) # rails 3+
        I18n::RESERVED_KEYS
      else
        I18n::Backend::Base::RESERVED_KEYS
      end

      string % values.except(*reserved_keys)
    end

    def flatten_key key, options
      scope = [*(options[:scope] || [])]
      scope.empty? ? key.to_s : "#{scope*'.'}.#{key}"
    end
  end
end