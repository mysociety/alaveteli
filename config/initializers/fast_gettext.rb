# -*- encoding : utf-8 -*-
AlaveteliLocalization.set_default_text_domain('app', File.join(Rails.root, 'locale'))

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

AlaveteliLocalization.set_default_locale_urls(AlaveteliConfiguration::include_default_locale_in_urls)
