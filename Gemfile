source 'https://rubygems.org'

gem 'rails', '4.0.13'

gem 'pg', '~> 0.18.4'

# New gem releases aren't being done. master is newer and supports Rails > 3.0
gem 'acts_as_versioned', :git => 'https://github.com/technoweenie/acts_as_versioned.git', :ref => '63b1fc8529d028'
gem 'active_model_otp', :git => 'https://github.com/heapsource/active_model_otp.git', :ref => 'c342283fe564bf'
gem 'charlock_holmes', '~> 0.7.3'
gem 'dalli', '~> 2.7.6'
gem 'dynamic_form', '~> 1.1.4'
# 4.1.0 has a bug in it which is fixed in a later version which does not have Ruby 1.9.3 support
gem 'exception_notification', '4.0.1'
gem 'fancybox-rails', '~> 0.3.1'
gem 'foundation-rails', '~> 5.5.3.2'
gem 'geoip', '~> 1.6.1'
gem 'gnuplot', '2.6.2'
gem 'htmlentities', '~> 4.3.4'
gem 'icalendar', '2.3.0'
gem 'jquery-rails', '~> 3.1.4'
gem 'jquery-ui-rails', '~> 5.0.0'
gem 'json', '~> 1.8.1'
gem 'holidays', '~> 2.2.0'
gem 'iso_country_codes', '~> 0.7.3'
gem 'mahoro', '~> 0.4'
gem 'newrelic_rpm'
gem 'net-http-local', '~> 0.1.2', :platforms => [:ruby_19]
gem 'net-purge', '~> 0.1.0'
gem 'nokogiri', '~> 1.6'
gem 'open4', '~> 1.3.4'
gem 'rack', '~> 1.5.5'
gem 'rack-ssl', '~> 1.3.2'
gem 'rack-utf8_sanitizer', '~> 1.3.0'
gem 'rails-i18n', '~> 4.0.9'
gem 'recaptcha', '~> 0.4.0', :require => 'recaptcha/rails'
gem 'rmagick', '~> 2.15.0'
gem 'ruby-msg', '~> 1.5.0',  :git => 'https://github.com/mysociety/ruby-msg.git', :ref => 'f9f928ed76c024b4bc3a08bc1a59beb62df36663'
gem 'sass', '3.4.21' # pinned because later versions cause problems (see blame)
gem 'secure_headers', '~> 3.1.2'
gem 'statistics2', '~> 0.54'
gem 'strip_attributes', :git => 'https://github.com/mysociety/strip_attributes.git', :branch => 'globalize3'
gem 'syslog_protocol', '~> 0.9.2'
gem 'thin', '~> 1.5.1'
gem 'vpim', '~> 13.11.11'
gem 'will_paginate', '~> 3.1.0'
gem 'xapian-full-alaveteli', '~> 1.2.21.1'
gem 'xml-simple', '~> 1.1.2', :require => 'xmlsimple'
gem 'zip', '~> 2.0.2'

# Gems related to internationalisation
gem 'gettext_i18n_rails', '~> 0.9.4' # Later versions cause error (see blame)
gem 'gettext', '~> 2.3.9'
gem 'globalize', '~> 4.0.3'
gem 'locale', '~> 2.0.8'
gem 'routing-filter', '~> 0.4.0'
gem 'unicode', '~> 0.4.4'
gem 'unidecoder', '~> 1.1.2'

# mime-types 3.0.0 requires Ruby 2.0.0, and _something_ is trying to update it
gem 'mime-types', '< 3.0.0'
# Bugfix https://github.com/mikel/mail/pull/1023
gem 'mail', :git => 'https://github.com/garethrees/mail', :ref => 'dc8832f'

# Feature flags
gem 'rollout'

# Assets
gem 'bootstrap-sass', '~> 2.3.2.2'
gem 'sass-rails', '~> 5.0.5'
gem 'compass-rails', '3.0.2'
gem 'coffee-rails', '~> 4.0.1'
gem 'uglifier', '~> 2.7.2'
gem 'therubyracer', '~> 0.12.2'

group :test do
  gem 'fakeweb', '~> 1.3.0'
  gem 'coveralls', :require => false
  gem 'capybara', '~> 2.7.0'
  gem 'delorean', '~> 2.1.0'
end

group :test, :development do
  gem 'bullet', '~> 5.1.0'
  gem 'factory_girl_rails', '~> 4.7.0'
  gem 'rspec-activemodel-mocks', '~> 1.0.1'
  gem 'rspec-rails', '~> 3.4.0'
  gem 'test-unit', '~> 3.1.0'
  gem 'pry-debugger', '~> 0.2.3', :platforms => :ruby_19
end

group :development do
  gem 'annotate', '~> 2.7.1'
  gem 'capistrano', '~> 2.15.9'
    gem 'net-ssh', '< 3.0.0'
  gem 'mailcatcher', '~> 0.6.4'
  gem 'quiet_assets', '~> 1.1.0'
  gem 'rdoc', '~> 3.12.2'
  gem 'better_errors', '~> 2.1.1', :platforms => :ruby_20
  gem 'binding_of_caller', '~> 0.7.2', :platforms => :ruby_20
end
