Encoding.default_external = 'UTF-8' if RUBY_VERSION.to_f >= 1.9
FastGettext.add_text_domain 'app', :path => File.join(Rails.root, 'locale'), :type => :po
FastGettext.default_text_domain = 'app'

I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)


