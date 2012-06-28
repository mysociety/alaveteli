# Work around bug in Debian Squeeze - see https://github.com/sebbacon/alaveteli/pull/297#issuecomment-4101012
if File.exist? "/etc/debian_version" and File.open("/etc/debian_version").read.strip =~ /^6\.0\.[45]$/
    if File.exist? "/lib/libuuid.so.1"
        require 'dl'
        DL::dlopen('/lib/libuuid.so.1')
    end
end
source :rubygems

gem 'rails', '2.3.14'
gem 'pg'

gem 'fast_gettext', '>= 0.6.0'
gem 'gettext_i18n_rails', '>= 0.6.0', :git => "git://github.com/sebbacon/gettext_i18n_rails.git"
gem 'gettext', '>= 1.9.3'
gem 'json', '~> 1.5.1'
gem 'mahoro'
gem 'memcache-client', :require => 'memcache'
gem 'locale', '>= 2.0.5'
gem 'net-http-local'
gem 'net-purge'
gem 'rack', '~> 1.1.0'
gem 'rdoc', '~> 2.4.3'
gem 'recaptcha', '~> 0.3.1', :require => 'recaptcha/rails'
# :require avoids "already initialized constant" warnings
gem 'rmagick', :require => 'RMagick'
gem 'routing-filter', '~> 0.2.4'
gem 'rspec', '~> 1.3.2'
gem 'rspec-rails', '~> 1.3.4'
gem 'ruby-msg', '~> 1.5.0'
gem 'test-unit', '~> 1.2.3' if RUBY_VERSION.to_f >= 1.9
gem 'vpim'
gem 'will_paginate', '~> 2.3.11'
# when 1.2.9 is released by the maintainer, we can stop using this fork:
gem 'xapian-full-alaveteli', '~> 1.2.9.5'
gem 'xml-simple'
gem 'zip'

group :test do
  gem 'fakeweb'
  gem 'rspec-rails', '~> 1.3.4'
  gem 'rake'
end

group :develop do
  gem 'ruby-debug'
  gem 'annotate'
end
