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

# New gem releases aren't being done. master is newer and supports Rails > 3.0
gem 'acts_as_versioned', :git => 'git://github.com/technoweenie/acts_as_versioned.git'
gem 'capistrano'
gem 'charlock_holmes'
gem 'dynamic_form'
gem 'exception_notification'
gem 'fastercsv', '>=1.5.5'
gem 'jquery-rails', '~> 2.1'
gem 'json'
gem 'mahoro'
gem 'net-http-local'
gem 'net-purge'
gem 'newrelic_rpm'
gem 'rack'
gem 'rake', '0.9.2.2'
gem 'rails-i18n'
gem 'rdoc'
gem 'recaptcha', '~> 0.3.1', :require => 'recaptcha/rails'
# :require avoids "already initialized constant" warnings
gem 'rmagick', :require => 'RMagick'
gem 'ruby-msg', '~> 1.5.0'
gem "statistics2", "~> 0.54"
gem 'syslog_protocol'
gem 'vpim'
gem 'will_paginate'
# when 1.2.9 is released by the maintainer, we can stop using this fork:
gem 'xapian-full-alaveteli', '~> 1.2.9.5'
gem 'xml-simple', :require => 'xmlsimple'
gem 'zip'

# Gems related to internationalisation
gem 'fast_gettext'
gem 'gettext_i18n_rails'
gem 'gettext'
# Use until this PR is merged: https://github.com/svenfuchs/globalize3/pull/191
gem 'globalize3', :git => 'git://github.com/henare/globalize3.git', :branch => 'not-null-empty-attributes'
gem 'locale'
gem 'routing-filter'
gem 'unicode'
gem 'unidecode'

group :test do
  gem 'fakeweb'
  gem 'coveralls', :require => false
  gem 'webrat'
  gem 'nokogiri'
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
  gem 'factory_girl_rails', '~> 1.7'
  gem 'rspec-rails'
  gem 'spork-rails'
end
