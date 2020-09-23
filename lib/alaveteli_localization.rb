# -*- encoding : utf-8 -*-
require 'alaveteli_localization/locale'
require 'alaveteli_localization/hyphenated_locale'
require 'alaveteli_localization/underscorred_locale'

class AlaveteliLocalization
  class << self
    def set_locales(available_locales, default_locale)
      # fallback locale and available locales
      available_locales = available_locales.to_s.
                            split(/ /).map { |locale| canonicalize(locale) }
      FastGettext.
        default_available_locales = available_locales.map { |x| x.to_sym }

      all_locales = available_locales.each_with_object([]) do |locale, memo|
        memo.concat(self_and_parents(to_hyphen(locale)))
      end
      I18n.available_locales = all_locales.uniq

      I18n.locale = I18n.default_locale = to_hyphen(default_locale).to_s
      FastGettext.default_locale = canonicalize(default_locale)
      RoutingFilter::Conditionallyprependlocale.locales = available_locales
    end

    def set_default_locale(locale)
      I18n.default_locale = to_hyphen(locale)
      FastGettext.default_locale = canonicalize(locale)
    end

    def set_default_text_domain(name, repos)
      FastGettext.add_text_domain name, :type => :chain, :chain => repos
      FastGettext.default_text_domain = name
    end

    def set_default_locale_urls(include_default_locale_in_urls)
      RoutingFilter::Locale.
        include_default_locale = include_default_locale_in_urls
    end

    def set_session_locale(*args)
      requested = args.compact.delete_if { |x| x.empty? }.first

      new_locale = FastGettext.best_locale_in(requested) || default_locale
      I18n.locale = to_hyphen(new_locale)
      FastGettext.locale = canonicalize(new_locale)
    end

    def with_locale(tmp_locale = nil, &block)
      tmp_locale = to_hyphen(tmp_locale) if tmp_locale
      I18n.with_locale(tmp_locale, &block)
    end

    def locale
      FastGettext.locale
    end

    def default_locale
      FastGettext.default_locale
    end

    def default_locale?(other)
      return false if other.nil?
      default_locale == other.to_s
    end

    def available_locales
      FastGettext.available_locales
    end

    def html_lang
      to_hyphen(locale)
    end

    private

    def canonicalize(locale)
      Locale.parse(locale).canonicalize
    end

    def to_hyphen(locale)
      Locale.parse(locale).hyphenate
    end

    def self_and_parents(locale)
      Locale.parse(locale).self_and_parents
    end
  end
end
