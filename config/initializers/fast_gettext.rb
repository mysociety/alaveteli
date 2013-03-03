FastGettext.add_text_domain 'app', :path => File.join(Rails.root, 'locale'), :type => :po
FastGettext.default_text_domain = 'app'

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

RoutingFilter::Locale.include_default_locale = AlaveteliConfiguration::include_default_locale_in_urls
