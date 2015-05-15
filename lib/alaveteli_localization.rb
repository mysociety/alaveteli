# -*- encoding : utf-8 -*-
class AlaveteliLocalization
    class << self
        def set_locales(available_locales, default_locale)
            # fallback locale and available locales
            available_locales = available_locales.split(/ /)
            FastGettext.default_available_locales = available_locales
            I18n.locale = default_locale
            I18n.available_locales = available_locales.map { |locale_name| locale_name.to_sym }
            I18n.default_locale = default_locale
            RoutingFilter::Conditionallyprependlocale.locales = available_locales
        end

        def set_default_text_domain(name, path)
            FastGettext.add_text_domain name, :path => path, :type => :po
            FastGettext.default_text_domain = name
        end

        def set_default_locale_urls(include_default_locale_in_urls)
            RoutingFilter::Locale.include_default_locale = include_default_locale_in_urls
        end
    end
end
