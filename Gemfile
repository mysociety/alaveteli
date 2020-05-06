# Versioning Policy
# =================
#
# In most cases gems should be added with a pessimistic constraint to their
# PATCH level:
#
#    gem 'foo', '~> 1.2.0'
#
# This will install the latest version of the 1.2 series. When 1.3 or 2.0 are
# released, we can assume there may be a breaking change.
#
# If we need to be more specific than this, apply one of the following
# guidelines. Use brief inline comments and commit messages to describe why the
# extra specificity is required. Links to changelogs are very appreciated.
#
# If we need greater than a specific PATCH level, specify that:
#
#    gem 'foo', '~> 1.2.0', '>= 1.2.7'
#
# This will install the latest version of 1.2.x, providing it is 1.2.7 or more.
#
# If there's a version that breaks compatibility (e.g, doesn't support our
# lowest Ruby version) add a compound requirement:
#
#    gem 'foo', '~> 1.2.0', '< 2.0.0'
#
# We tend to keep the rails gem pinned to a specific version for easy reference.
#
# Dependencies of Dependencies
# ============================
#
# Sometimes a gem that we rely on might have a dependency that breaks on update.
# Ideally the problem should be fixed, but failing that, specify a working
# version of the dependency alongside the gem we rely on:
#
#    gem 'foo', '~> 1.2.0'
#      gem 'bar', '< 3.0.0'
#
# Platform Constraints
# ====================
#
# Only use platform constraints that are supported by the lowest version of
# bundler in use, otherwise they won't work. We can't use conditionals like
# `if RUBY_VERSION` because they are specific to the individual developer
# machine.
#
# Gems from GitHub
# ================
#
# Sometimes we need to apply fixes to gems. Generally you'll want to fork the
# code to the mysociety organisation, fix the problem and use that git ref. This
# is a sure-fire way to out of date dependencies, so getting back on the
# upstream release as soon as possible is favourable. Its also better to use
# the ref option rather than branch. For example, if you rebase your bugfix
# branch on upstream/master and force push it, the locked SHA will no longer
# exist on the specified branch. This makes previous versions of Alaveteli
# uninstallable.
#
# Upgrading Gems
# ==============
#
# We use Gemnasium, which alerts us to gem updates.
#
# Most gems will be pessimistically locked at the PATCH level, so you can just
# run `bundle update foo`.
#
#    gem 'foo', '~> 1.2.0'
#
# When a new MINOR or MAJOR release is available, bump the version to the new
# PATCH level and run `bundle update foo`.
#
#    - gem 'foo', '~> 1.2.0'
#    + gem 'foo', '~> 1.3.0'
#
# After running `bundle update foo`, run the specs and read the gem's changelog
# to check for anything that looks like it may impact on our code. All going
# well, the change can be committed. If you find a breakage, either fix our code
# to be compatible with the new version or add a compound requirement less than
# the new version. It is always preferable to upgrade our code.
source 'https://rubygems.org'

# See instructions in Gemfile.rails_next
def rails_upgrade?
  %w[1 true].include?(ENV['RAILS_UPGRADE'])
end

gem 'rails', rails_upgrade? ? '~> 5.2.4' : '5.1.7'

gem 'pg', '~> 0.20.0'

# New gem releases aren't being done. master is newer and supports Rails > 3.0
gem 'acts_as_versioned', :git => 'https://github.com/technoweenie/acts_as_versioned.git', :ref => '63b1fc8529d028'
gem 'active_model_otp', :git => 'https://github.com/heapsource/active_model_otp.git', :ref => '55d93a3979'
gem 'bcrypt', '~> 3.1.13'
gem 'cancancan', '~> 1.17.0', '< 2.0.0'
gem 'charlock_holmes', '~> 0.7.7'
gem 'dalli', '~> 2.7.0'
gem 'dynamic_form', '~> 1.1.0'
gem 'exception_notification', ['~> 4.1.0', '< 4.1.2']
gem 'fancybox-rails', '~> 0.3.0'
gem 'gnuplot', '~> 2.6.0'
gem 'htmlentities', '~> 4.3.0'
gem 'icalendar', '~> 2.4.0'
gem 'jquery-rails', '~> 4.3.5'
gem 'jquery-ui-rails', '~> 6.0.0'
gem 'json', ['~> 1.8.0', '< 2.0.0']
gem 'holidays', '~> 4.7.0', '< 5.0.0'
gem 'iso_country_codes', '~> 0.7.8'
gem 'mail', '~> 2.6.6'
gem 'maxmind-db', '~> 1.0.0'
gem 'mahoro', '~> 0.4'
gem 'newrelic_rpm'
gem 'nokogiri', '~> 1.10.8'
gem 'open4', '~> 1.3.0'
gem 'rack', '~> 2.0.8'
gem 'rack-ssl', '~> 1.4.0'
gem 'rack-utf8_sanitizer', '~> 1.3.0'
gem 'recaptcha', '~> 4.9.0', '< 4.10.0', :require => 'recaptcha/rails'
gem 'rmagick', '~> 2.16.0'
gem 'rolify', '~> 5.2.0'
gem 'ruby-msg', '~> 1.5.0', :git => 'https://github.com/mysociety/ruby-msg.git', :branch => 'ascii-encoding'
gem 'rubyzip', '~> 1.3.0', '< 2.0.0'
gem 'secure_headers', '~> 3.9.0'
gem 'statistics2', '~> 0.54'
gem 'strip_attributes', :git => 'https://github.com/mysociety/strip_attributes.git', :ref => 'c1c14da'
gem 'stripe', '~> 3.29.0'
gem 'syslog_protocol', '~> 0.9.0'
gem 'thin', '~> 1.5.0', '< 1.6.0'
gem 'vpim', '~> 13.11.11'
gem 'will_paginate', '~> 3.1.8'
gem 'xapian-full-alaveteli', '~> 1.2.21.1'
gem 'xml-simple', '~> 1.1.0', :require => 'xmlsimple'
gem 'zip_tricks', '~> 5.0.0'

# Gems only used by the research export task
gem 'gender_detector', '~> 1.0.0'

# Gems related to internationalisation
gem 'i18n', ['~> 0.9.0', '< 0.9.3']
gem 'rails-i18n', '~> 5.1.0'
gem 'gettext_i18n_rails', '~> 0.10.1'
  gem 'fast_gettext', '< 1.2.0'
gem 'gettext', '~> 2.3.0'
gem 'globalize', '~> 5.2.0'
gem 'locale', '~> 2.0.0', '< 2.1.0'
gem 'routing-filter', '~> 0.6.2'
gem 'unicode', '~> 0.4.4'
gem 'unidecoder', '~> 1.1.0'
gem 'money', '~> 6.13.6'

# mime-types 3.0.0 requires Ruby 2.0.0, and _something_ is trying to update it
gem 'mime-types', '< 3.0.0', require: false

# Assets
gem 'bootstrap-sass', '~> 2.3.2.2'
gem 'sass-rails', '~> 5.0.7'
gem 'compass-rails', '~> 3.1.0'
gem 'coffee-rails', '~> 4.2.0'
gem 'uglifier', '~> 3.2.0'
gem 'therubyracer', '~> 0.12.0'

# Feature flags
gem 'alaveteli_features', :path => 'gems/alaveteli_features'

group :test do
  gem 'webmock', '~> 3.5.1'
  gem 'coveralls', '~> 0.8.0', :require => false
  gem 'capybara', '~> 3.5.0'
  gem 'delorean', '~> 2.1.0'
  gem 'stripe-ruby-mock', git: 'https://github.com/gbp/stripe-ruby-mock',
                          branch: 'develop'
  gem('rails-controller-testing')
end

group :test, :development do
  gem 'bullet', '~> 5.7.6'
  gem 'factory_bot_rails', '~> 4.10.0'
  gem 'oink', '~> 0.10.1'
  gem 'rspec-activemodel-mocks', '~> 1.1.0'
  gem 'rspec-rails', '~> 3.7.2'
  gem 'pry', '~> 0.12.2'
  gem 'pry-byebug', '~> 3.7.0'
    gem 'public_suffix', '~> 2.0.0', '< 3.0.0'
end

group :development do
  gem 'annotate', '~> 2.7.0'
  gem 'capistrano', '~> 2.15.0', '< 3.0.0'
    gem 'net-ssh', ['~> 2.9.0', '< 3.0.0']
      gem 'net-ssh-gateway', ['>= 1.1.0', '< 2.0.0']
  gem 'launchy', '~> 2.4.0'
  gem 'listen', '~> 3.0.5'
  gem 'web-console', '>= 3.3.0'
  gem 'rubocop', '~> 0.63.1'
end
