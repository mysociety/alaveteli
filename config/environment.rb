# Be sure to restart your web server when you modify this file.
if RUBY_VERSION.to_f >= 1.9
    # the default encoding for IO is utf-8, and we use utf-8 internally
    Encoding.default_external = Encoding.default_internal = Encoding::UTF_8
    # Suppress warning messages and require inflector to avoid iconv deprecation message
    # "iconv will be deprecated in the future, use String#encode instead." when loading
    # it as part of rails
    original_verbose, $VERBOSE = $VERBOSE, nil
    require 'active_support/inflector'
    # Activate warning messages again.
    $VERBOSE = original_verbose
    require 'yaml'
    YAML::ENGINE.yamler = "syck"
end

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.18' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# MySociety specific helper functions
$:.push(File.join(File.dirname(__FILE__), '../commonlib/rblib'))
# ... if these fail to include, you need the commonlib submodule from git
# (type "git submodule update --init" in the whatdotheyknow directory)

$:.unshift(File.join(File.dirname(__FILE__), '../vendor/plugins/globalize2/lib'))

load "validate.rb"
load "config.rb"
load "format.rb"
load "debug_helpers.rb"
load "util.rb"
# Patch Rails::GemDependency to cope with older versions of rubygems, e.g. in Debian Lenny
# Restores override removed in https://github.com/rails/rails/commit/c20a4d18e36a13b5eea3155beba36bb582c0cc87
# without effecting method behaviour
# and adds fallback gem call removed in https://github.com/rails/rails/commit/4c3725723f15fab0a424cb1318b82b460714b72f
require File.join(File.dirname(__FILE__), '../lib/old_rubygems_patch')
require 'configuration'

# Application version
ALAVETELI_VERSION = '0.7'

Rails::Initializer.run do |config|
  # Load intial mySociety config
  if ENV["RAILS_ENV"] == "test"
      MySociety::Config.set_file(File.join(config.root_path, 'config', 'test'), true)
  else
      MySociety::Config.set_file(File.join(config.root_path, 'config', 'general'), true)
  end
  MySociety::Config.load_default

  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Allow some extra tags to be whitelisted in the 'sanitize' helper method
  config.action_view.sanitized_allowed_tags

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{Rails.root}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # TEMP: uncomment this to turn on logging in production environments
  # config.log_level = :debug
  #
  # Specify gems that this application depends on and have them installed with rake gems:install
  #GettextI18nRails.translations_are_html_safe = true

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  # This is the timezone that times and dates are displayed in
  # Note that having set a zone, the Active Record
  # time_zone_aware_attributes flag is on, so times from models
  # will be in this time zone
  config.time_zone = Configuration::time_zone

  config.after_initialize do
     require 'routing_filters.rb'
  end

  config.autoload_paths << "#{RAILS_ROOT}/lib/mail_handler"

  # See Rails::Configuration for more options
  ENV['RECAPTCHA_PUBLIC_KEY'] = Configuration::recaptcha_public_key
  ENV['RECAPTCHA_PRIVATE_KEY'] = Configuration::recaptcha_private_key
end

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Domain for URLs (so can work for scripts, not just web pages)
ActionMailer::Base.default_url_options[:host] = Configuration::domain

# So that javascript assets use full URL, so proxied admin URLs read javascript OK
if (Configuration::domain != "")
    ActionController::Base.asset_host = Proc.new { |source, request|
        if ENV["RAILS_ENV"] != "test" && request.fullpath.match(/^\/admin\//)
            Configuration::admin_public_url
        else
            Configuration::domain
        end
    }
end

# fallback locale and available locales
available_locales = Configuration::available_locales.split(/ /)
default_locale = Configuration::default_locale

FastGettext.default_available_locales = available_locales
I18n.locale = default_locale
I18n.available_locales = available_locales.map {|locale_name| locale_name.to_sym}
I18n.default_locale = default_locale

# Customise will_paginate URL generation
WillPaginate::ViewHelpers.pagination_options[:renderer] = 'WillPaginateExtension::LinkRenderer'

# Load monkey patches and other things from lib/
require 'ruby19.rb'
require 'activesupport_cache_extensions.rb'
require 'timezone_fixes.rb'
require 'use_spans_for_errors.rb'
require 'make_html_4_compliant.rb'
require 'activerecord_errors_extensions.rb'
require 'willpaginate_extension.rb'
require 'sendmail_return_path.rb'
require 'i18n_fixes.rb'
require 'rack_quote_monkeypatch.rb'
require 'world_foi_websites.rb'
require 'alaveteli_external_command.rb'
require 'quiet_opener.rb'
require 'mail_handler'

if !Configuration.exception_notifications_from.blank? && !Configuration.exception_notifications_to.blank?
  ExceptionNotification::Notifier.sender_address = Configuration::exception_notifications_from
  ExceptionNotification::Notifier.exception_recipients = Configuration::exception_notifications_to
end
