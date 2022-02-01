class AlaveteliLocalization
  class Railtie < Rails::Railtie
    config.before_configuration do
      require 'rails_i18n/common_pluralizations/one_other'

      require 'alaveteli_localization/locale'
      require 'alaveteli_localization/hyphenated_locale'
      require 'alaveteli_localization/underscorred_locale'

      require 'routing_filters'
      require 'i18n_fixes'

      paths = ['locale']
      paths << 'locale_alaveteli_pro' if AlaveteliConfiguration.
        enable_alaveteli_pro

      repos = paths.map do |path|
        FastGettext::TranslationRepository.build('app', path: path, type: :po)
      end
      AlaveteliLocalization.set_default_text_domain('app', repos)

      I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

      AlaveteliLocalization.set_default_locale_urls(
        AlaveteliConfiguration.include_default_locale_in_urls
      )

      AlaveteliLocalization.set_locales(
        AlaveteliConfiguration.available_locales,
        AlaveteliConfiguration.default_locale
      )
    end
  end
end
