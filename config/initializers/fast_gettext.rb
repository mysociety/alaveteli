FastGettext.add_text_domain 'app', :path => File.join(Rails.root, 'locale'), :type => :po
FastGettext.default_text_domain = 'app'
