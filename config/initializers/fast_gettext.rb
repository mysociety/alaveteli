# -*- encoding : utf-8 -*-


repos = [ FastGettext::TranslationRepository.build('app',
                                                   :path => 'locale',
                                                   :type => :po) ]
if AlaveteliConfiguration::enable_alaveteli_pro
  pro_repo = FastGettext::TranslationRepository.build('app',
    :path => 'locale_alaveteli_pro',
    :type => :po)
  repos << pro_repo
end
AlaveteliLocalization.set_default_text_domain('app', repos)

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

AlaveteliLocalization.set_default_locale_urls(AlaveteliConfiguration::include_default_locale_in_urls)
