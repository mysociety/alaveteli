# Work around bug in Debian Squeeze - see https://github.com/mysociety/alaveteli/pull/297#issuecomment-4101012
if File.exist? "/etc/debian_version" and File.open("/etc/debian_version").read.strip =~ /^(squeeze.*|6\.0\.[45])$/
    if File.exist? "/lib/libuuid.so.1"
        require 'dl'
        DL::dlopen('/lib/libuuid.so.1')
    end
end
source :rubygems

# A fork of rails that is kept up to date with security patches
git "git://github.com/mysociety/rails.git", :tag => "v2.3.17.1" do
  gem 'rails'
end
gem 'pg'

gem 'fast_gettext', '>= 0.6.0'
gem 'fastercsv', '>=1.5.5'
gem 'gettext_i18n_rails', '>= 0.7.1'
gem 'gettext', '~> 2.3.3'
gem 'json', '~> 1.5.5'
gem 'mahoro'
gem 'mail', :platforms => :ruby_19
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
gem 'rake', '0.9.2.2'
gem 'ruby-msg', '~> 1.5.0'
gem 'vpim'
gem 'will_paginate', '~> 2.3.11'
# when 1.2.9 is released by the maintainer, we can stop using this fork:
gem 'xapian-full-alaveteli', '~> 1.2.9.5'
gem 'xml-simple'
gem 'zip'
gem 'capistrano'
gem 'syslog_protocol'
gem 'newrelic_rpm'
# erubis is required by rails_xss. Both erubis and rails_xss can be removed after upgrading to Rails 3.
gem 'erubis'

group :test do
  gem 'fakeweb'
  gem 'rspec-rails', '~> 1.3.4'
  gem 'test-unit', '~> 1.2.3', :platforms => :ruby_19
end

group :development do
  gem 'mailcatcher'
end

group :develop do
  gem 'ruby-debug', :platforms => :ruby_18
  gem 'ruby-debug19', :platforms => :ruby_19
  gem 'bootstrap-sass'
  gem 'compass'
  gem 'annotate'
end
