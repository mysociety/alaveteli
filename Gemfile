# Work around bug in Debian Squeeze - see https://github.com/mysociety/alaveteli/pull/297#issuecomment-4101012
if File.exist? "/etc/debian_version" and File.open("/etc/debian_version").read.strip =~ /^(squeeze.*|6\.0\.[45])$/
    if File.exist? "/lib/libuuid.so.1"
        require 'dl'
        DL::dlopen('/lib/libuuid.so.1')
    end
end
source 'https://rubygems.org'

gem 'rails', '3.1.12'
gem 'pg'

gem 'fast_gettext', '>= 0.6.0'
gem 'fastercsv', '>=1.5.5'
gem 'gettext_i18n_rails', '>= 0.7.1'
gem 'gettext', '~> 2.3.3'
gem 'json'
gem 'mahoro'
gem 'memcache-client', :require => 'memcache'
gem 'locale', '>= 2.0.5'
gem 'net-http-local'
gem 'net-purge'
gem 'rack'
gem 'rdoc'
gem 'recaptcha', '~> 0.3.1', :require => 'recaptcha/rails'
# :require avoids "already initialized constant" warnings
gem 'rmagick', :require => 'RMagick'
gem 'routing-filter', '~> 0.2.4'
gem 'rake', '0.9.2.2'
gem 'ruby-msg', '~> 1.5.0'
gem 'vpim'
gem 'will_paginate'
# when 1.2.9 is released by the maintainer, we can stop using this fork:
gem 'xapian-full-alaveteli', '~> 1.2.9.5'
gem 'xml-simple'
gem 'zip'
gem 'capistrano'
gem 'syslog_protocol'
gem 'newrelic_rpm'
# Use until this PR is merged: https://github.com/svenfuchs/globalize3/pull/191
gem 'globalize3', :git => 'git://github.com/henare/globalize3.git', :branch => 'not-null-empty-attributes'
# New gem releases aren't being done. master is newer and supports Rails > 3.0
gem 'acts_as_versioned', :git => 'git://github.com/technoweenie/acts_as_versioned.git'
gem 'dynamic_form'
gem 'exception_notification'

group :test do
  gem 'fakeweb'
  gem 'coveralls', :require => false
  gem 'webrat'
end

group :development do
  gem 'mailcatcher'
end

group :develop do
  gem 'ruby-debug', :platforms => :ruby_18
  gem 'debugger', :platforms => :ruby_19
  gem 'bootstrap-sass'
  gem 'compass'
  gem 'annotate'
end

group :test, :development do
  gem 'rspec-rails'
  gem 'spork-rails'
end
