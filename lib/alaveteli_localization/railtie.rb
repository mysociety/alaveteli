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

      if Rails.version < '7.0.0' && Rails.env.development?
        ##
        # Ideally the following would only be called in the `after_initialize`
        # hook but this leads to an error when booting Rails 6.1 in development
        # mode. (As config.cache_classes = false)
        #
        # This due Alaveteli not yet using the new Zeitwork autoloading feature
        # and Rails attempts to render a deprecation warning which happens to
        # includes an I18n translation so requires the default locale to be
        # setup.
        #
        # Once we support Zeitwork (which is needed for Rails 7) then this can
        # be removed.
        #
        # See: https://github.com/mysociety/alaveteli/issues/5382
        #
        AlaveteliLocalization.set_locales(
          AlaveteliConfiguration.available_locales,
          AlaveteliConfiguration.default_locale
        )
      end
    end

    config.after_initialize do
      AlaveteliLocalization.set_locales(
        AlaveteliConfiguration.available_locales,
        AlaveteliConfiguration.default_locale
      )
    end
  end
end
