class AlaveteliLocalization
    class << self
        def set_locales(available_locales, default_locale)
            # fallback locale and available locales
            available_locales = available_locales.split(/ /)
            FastGettext.default_available_locales = available_locales
            I18n.locale = default_locale
            I18n.available_locales = available_locales.map { |locale_name| locale_name.to_sym }
            I18n.default_locale = default_locale
        end

    end
end
