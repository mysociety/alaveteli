source 'https://rubygems.org'

gem 'rails', '3.2.21'

gem 'pg', '~> 0.17.1'

# New gem releases aren't being done. master is newer and supports Rails > 3.0
gem 'acts_as_versioned', :git => 'https://github.com/technoweenie/acts_as_versioned.git', :ref => '63b1fc8529d028'
gem 'active_model_otp', :git => 'https://github.com/garethrees/active_model_otp.git', :ref => '0eb977b4c6dafd'
gem 'charlock_holmes', '~> 0.6.9.4'
gem 'dynamic_form', '~> 1.1.4'
gem 'exception_notification', '~> 3.0.1'
gem 'fancybox-rails', '~> 0.2.1'
gem 'foundation-rails', '~> 5.2.1.0'
gem 'geoip', '~> 1.6.1'
gem 'icalendar', '1.4.3'
gem 'jquery-rails', '~> 3.1.3'
gem 'jquery-ui-rails', '~> 4.1.0'
gem 'json', '~> 1.8.1'
gem 'holidays', '~> 1.2.0'
gem 'iso_country_codes', '~> 0.6.1'
gem 'mahoro', '~> 0.4'
gem 'memcache-client', '~> 1.8.5'
gem 'net-http-local', '~> 0.1.2', :platforms => [:ruby_19]
gem 'net-purge', '~> 0.1.0'
gem 'nokogiri', '~> 1.5.9'
gem 'open4', '~> 1.3.4'
gem 'rack', '~> 1.4.6'
gem 'rack-utf8_sanitizer', '~> 1.3.0'
gem 'rake', '0.9.2.2'
gem 'rails-i18n', '~> 0.7.3'
gem 'recaptcha', '~> 0.4.0', :require => 'recaptcha/rails'
gem 'rmagick', '~> 2.14.0'
gem 'ruby-msg', '~> 1.5.0',  :git => 'https://github.com/mysociety/ruby-msg.git'
gem 'secure_headers', '~> 2.0.2'
gem 'statistics2', '~> 0.54'
gem 'strip_attributes', :git => 'https://github.com/mysociety/strip_attributes.git', :branch => 'globalize3'
gem 'syslog_protocol', '~> 0.9.2'
gem 'thin', '~> 1.5.1'
gem 'vpim', '~> 13.11.11'
gem 'will_paginate', '~> 3.0.5'
gem 'xapian-full-alaveteli', '~> 1.2.21.1'
gem 'xml-simple', '~> 1.1.2', :require => 'xmlsimple'
gem 'zip', '~> 2.0.2'

# Gems related to internationalisation
gem 'fast_gettext', '~> 0.7.0'
gem 'gettext_i18n_rails', '~> 0.9.4'
gem 'gettext', '~> 2.3.9'
gem 'globalize3', :git => 'https://github.com/globalize/globalize.git', :ref => '5fd95f2389dff1'
gem 'locale', '~> 2.0.8'
gem 'routing-filter', '~> 0.3.1'
gem 'unicode', '~> 0.4.4'
gem 'unidecoder', '~> 1.1.2'

group :assets do
  gem 'bootstrap-sass', '~> 2.3.1.2'
  gem 'sass-rails', '~> 3.2.3'
  gem 'compass-rails', '2.0.0'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '~> 2.7.2'
  gem 'therubyracer', '~> 0.12.0'
end

group :production do
  gem 'newrelic_rpm'
end

group :test do
  gem 'fakeweb', '~> 1.3.0'
  gem 'coveralls', :require => false
  gem 'capybara', '~> 2.5.0'
end

group :test, :development do
  gem 'bullet', '~> 4.14.6'
  gem 'factory_girl_rails', '~> 1.7'
  gem 'pry', '~> 0.10.2'
  gem 'rspec-activemodel-mocks', '~> 1.0.1'
  gem 'rspec-rails', '3.0.2'
  gem 'spork-rails', '~> 3.2.1'
end

group :development do
  gem 'capistrano', '~> 2.15.4'
  gem 'mailcatcher', '~> 0.5.11'
  gem 'quiet_assets', '~> 1.0.2'
  gem 'rdoc', '~> 3.12.2'
end

group :debug do
  gem 'debugger', '~> 1.6.0', :platforms => :ruby_19
  gem 'annotate', '~> 2.5.0'
end
