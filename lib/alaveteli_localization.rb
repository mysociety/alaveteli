# -*- encoding : utf-8 -*-
class AlaveteliLocalization
  class << self
    def set_locales(available_locales, default_locale)
      # fallback locale and available locales
      available_locales = available_locales.split(/ /)
      FastGettext.default_available_locales = available_locales.
                                                map { |x| x.to_sym }
      I18n.available_locales = available_locales.map do |locale_name|
        locale_name.gsub("_", '-').to_sym
      end
      I18n.locale = I18n.default_locale = default_locale.to_s.gsub("_", '-')
      FastGettext.default_locale = default_locale
      RoutingFilter::Conditionallyprependlocale.locales = available_locales
    end

    def set_default_locale(locale)
      I18n.default_locale = locale.to_s.gsub("_", '-').to_sym
      FastGettext.default_locale = locale.to_s.gsub("-", '_')
    end

    def set_default_text_domain(name, repos)
      FastGettext.add_text_domain name, :type => :chain, :chain => repos
      FastGettext.default_text_domain = name
    end

    def set_default_locale_urls(include_default_locale_in_urls)
      RoutingFilter::Locale.include_default_locale = include_default_locale_in_urls
    end

    def locale
      FastGettext.locale.to_sym
    end

    def default_locale
      FastGettext.default_locale.to_sym
    end

    def available_locales
      FastGettext.default_available_locales
    end
  end
end
