FastGettext.add_text_domain 'app', :path => File.join(RAILS_ROOT, 'locale'), :type => :po
FastGettext.default_available_locales = ['en'] #all you want to allow
FastGettext.default_text_domain = 'app'