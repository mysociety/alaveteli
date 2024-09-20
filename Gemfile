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

gem 'rails', '~> 7.0.8'

gem 'pg', '~> 1.5.7'

# New gem releases aren't being done. master is newer and supports Rails > 3.0
gem 'addressable', '~> 2.8.7'
gem 'acts_as_versioned', git: 'https://github.com/mysociety/acts_as_versioned.git',
                         ref: '13e928b'
gem 'active_model_otp'
gem 'activejob-uniqueness', '~> 0.2.5'
gem 'bcrypt', '~> 3.1.20'
gem 'cancancan', '~> 3.6.1'
gem 'charlock_holmes', '~> 0.7.9'
gem 'dalli', '~> 3.2.8'
gem 'exception_notification', '~> 4.5.0'
gem 'fancybox-rails', '~> 0.3.0'
gem 'friendly_id', '~> 5.5.1'
gem 'gnuplot', '~> 2.6.0'
gem 'htmlentities', '~> 4.3.0'
gem 'icalendar', '~> 2.10.2'
gem 'jquery-rails', '~> 4.6.0'
gem 'jquery-ui-rails', '~> 6.0.0'
gem 'json', '~> 2.7.2'
gem 'holidays', '~> 8.8.0'
gem 'iso_country_codes', '~> 0.7.8'
gem 'mail', '~> 2.8.1'
gem 'maxmind-db', '~> 1.2.0'
gem 'mahoro', '~> 0.5'
gem 'nokogiri', '~> 1.16.7'
gem 'open4', '~> 1.3.0'
gem 'puma', '~> 6.4.2'
gem 'rack', '~> 2.2.9'
gem 'rack-utf8_sanitizer', '~> 1.9.1'
gem 'recaptcha', '~> 5.17.0', require: 'recaptcha/rails'
gem 'matrix', '~> 0.4.2'
gem 'mini_magick', '~> 4.13.1'
gem 'net-protocol', '~> 0.1.3'
gem 'redcarpet', '~> 3.6.0'
gem 'redis', '~> 4.8.1'
gem 'rolify', '~> 6.0.1'
gem 'ruby-msg', '~> 1.5.0', git: 'https://github.com/mysociety/ruby-msg.git', branch: 'ascii-encoding'
gem 'rubyzip', '~> 2.3.2'
gem 'secure_headers', '~> 6.7.0'
gem 'sidekiq', '~> 6.5.12'
gem 'sidekiq-limit_fetch', '~> 4.4.1'
gem 'statistics2', '~> 0.54'
gem 'strip_attributes', git: 'https://github.com/mysociety/strip_attributes.git', branch: 'globalize3-rails7'
gem 'stripe', '~> 5.55.0'
gem 'syck', '~> 1.4.1', require: false
gem 'syslog_protocol', '~> 0.9.0'
gem 'vpim', '~> 24.2.20'
gem 'will_paginate', '~> 4.0.1'
gem 'xapian-full-alaveteli', '~> 1.4.22.1'
gem 'xml-simple', '~> 1.1.9', require: 'xmlsimple'
gem 'zip_tricks', '~> 5.6.0'

# Gems only used by the research export task
gem 'gender_detector', '~> 2.0.0'

# Gems related to internationalisation
gem 'i18n', '~> 1.14.5'
gem 'rails-i18n', '~> 7.0.5'
gem 'gettext_i18n_rails', '~> 1.13.0'
  gem 'fast_gettext', '~> 3.1.0'
gem 'gettext', '~> 3.4.9'
gem 'globalize', '~> 6.3.0'
gem 'locale', '~> 2.1.4'
gem 'unicode', '~> 0.4.4'
gem 'unidecoder', '~> 1.1.0'
gem 'money', '~> 6.19.0'

# mime-types 3.0.0 requires Ruby 2.0.0, and _something_ is trying to update it
gem 'mime-types', '< 4.0.0', require: false

# Assets
gem 'bootstrap-sass', '~> 2.3.2.2'
gem 'mini_racer', '~> 0.16.0'
gem 'sass-rails', '~> 5.0.8'
gem 'sprockets', git: 'https://github.com/rails/sprockets', ref: '3.x'
gem 'uglifier', '~> 4.2.0'
# Modern Assets
gem 'importmap-rails', '~> 2.0.1'
gem 'stimulus-rails', '~> 1.3.4'
gem 'turbo-rails', '~> 2.0.6'

# Feature flags
gem 'alaveteli_features', path: 'gems/alaveteli_features'

# Storage backends
gem 'aws-sdk-s3', require: false
gem 'google-cloud-storage', '~> 1.47', require: false

# Storage content analyzers
gem 'excel_analyzer', path: 'gems/excel_analyzer', require: false

# AI
gem "faraday", "~> 2.10"
gem 'langchainrb_rails', '~> 0.1.10'
gem 'pgvector', '~> 0.2'
gem 'sequel', '~> 5.68.0'
gem 'neighbor', '~> 0.4.3'
gem 'tiktoken_ruby', '~> 0.0.9'

group :test do
  gem 'fivemat', '~> 1.3.7'
  gem 'webmock', '~> 3.23.1'
  gem 'simplecov', '~> 0.22.0'
  gem 'simplecov-lcov', '~> 0.7.0'
  gem 'capybara', '~> 3.40.0'
  gem 'stripe-ruby-mock', git: 'https://github.com/stripe-ruby-mock/stripe-ruby-mock',
                          ref: '6ceea96'
  gem 'rails-controller-testing'
end

group :test, :development do
  gem 'bullet', '~> 7.2.0'
  gem 'factory_bot_rails', '~> 6.4.3'
  gem 'oink', '~> 0.10.1'
  gem 'rspec-activemodel-mocks', '~> 1.2.0'
  gem 'rspec-rails', '~> 7.0.1'
  gem 'pry', '~> 0.14.2'
  gem 'vcr', '~> 6.3.1'
end

group :development do
  gem 'annotate', '< 3.2.1'
  gem 'capistrano', '~> 2.15.11'
    gem 'net-ssh', '~> 7.2.3'
      gem 'net-ssh-gateway', '>= 1.1.0', '< 3.0.0'
  gem 'launchy', '< 3.1.0'
  gem 'web-console', '>= 3.3.0'
  gem 'rubocop', '~> 1.66.1', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end
