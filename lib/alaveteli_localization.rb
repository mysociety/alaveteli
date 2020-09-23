# -*- encoding : utf-8 -*-
require 'alaveteli_localization/locale'
require 'alaveteli_localization/hyphenated_locale'
require 'alaveteli_localization/underscorred_locale'

class AlaveteliLocalization
  class << self
    def set_locales(available_locales, default_locale)
      available, default = parse_locales(available_locales, default_locale)

      set_fast_gettext_locales(available, default)
      set_i18n_locales(available, default)
      set_conditionally_prepend_locale_locales(available, default)
    end

    def set_default_text_domain(name, repos)
      FastGettext.add_text_domain name, type: :chain, chain: repos
      FastGettext.default_text_domain = name
    end

    def set_default_locale_urls(include_default_locale_in_urls)
      RoutingFilter::Locale.
        include_default_locale = include_default_locale_in_urls
    end

    def set_default_locale(locale)
      locale = Locale.parse(locale)
      I18n.default_locale = locale.hyphenate.to_s
      FastGettext.default_locale = locale.canonicalize.to_s
    end

    def set_session_locale(*args)
      requested = args.compact.delete_if(&:empty?).first
      new_locale = FastGettext.best_locale_in(requested) || default_locale
      locale = Locale.parse(new_locale)

      I18n.locale = Locale.parse(new_locale).hyphenate
      FastGettext.locale = Locale.parse(new_locale).canonicalize

      locale.canonicalize.to_s
    end

    def with_locale(tmp_locale = nil, &block)
      tmp_locale = Locale.parse(tmp_locale).hyphenate if tmp_locale
      I18n.with_locale(tmp_locale, &block)
    end

    def available_locales
      FastGettext.available_locales
    end

    def default_locale
      FastGettext.default_locale
    end

    def default_locale?(other)
      return false if other.nil?
      default_locale == other.to_s
    end

    def locale
      FastGettext.locale
    end

    def html_lang
      Locale.parse(locale).hyphenate
    end

    private

    def set_fast_gettext_locales(available, default)
      FastGettext.default_available_locales =
        available.map { |locale| locale.canonicalize.to_sym }

      FastGettext.default_locale = default.canonicalize.to_s
    end

    def set_i18n_locales(available, default)
      i18n_locales = available.each_with_object([]) do |locale, memo|
        memo.concat(locale.self_and_parents)
      end

      I18n.available_locales = i18n_locales.map(&:to_s).uniq
      I18n.locale = I18n.default_locale = default.hyphenate.to_s
    end

    def set_conditionally_prepend_locale_locales(available, _default)
      RoutingFilter::Conditionallyprependlocale.locales = available.map(&:to_s)
    end

    # Parse String locales to Locale instances
    def parse_locales(available_locales, default_locale)
      [available_locales.to_s.split(/ /).map { |locale| Locale.parse(locale) },
       Locale.parse(default_locale)]
    end
  end
end
