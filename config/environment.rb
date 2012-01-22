# Be sure to restart your web server when you modify this file.


# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# MySociety specific helper functions
$:.push(File.join(File.dirname(__FILE__), '../commonlib/rblib'))
# ... if these fail to include, you need the commonlib submodule from git
# (type "git submodule update --init" in the whatdotheyknow directory)

# ruby-ole and ruby-msg.  We use a custom ruby-msg to avoid a name conflict
$:.unshift(File.join(File.dirname(__FILE__), '../vendor/ruby-ole/lib'))
$:.unshift(File.join(File.dirname(__FILE__), '../vendor/ruby-msg/lib'))
$:.unshift(File.join(File.dirname(__FILE__), '../vendor/plugins/globalize2/lib'))

require 'memcache'

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

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # TEMP: uncomment this to turn on logging in production environments
  # config.log_level = :debug
  #
  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "locale", :version => '>=2.0.5'
  config.gem "gettext", :version => '>=1.9.3'
  config.gem "fast_gettext", :version => '>=0.4.8'
  config.gem "rack", :version => '1.1.0'
  config.gem "rdoc", :version => '>=2.4.3'
  config.gem "recaptcha", :lib => "recaptcha/rails"
  config.gem 'rspec', :lib => false, :version => '1.3.1'
  config.gem 'rspec-rails', :lib => false, :version => '1.3.3'
  config.gem 'routing-filter'
  config.gem 'will_paginate', :version => '~> 2.3.11', :source => 'http://gemcutter.org'
  #GettextI18nRails.translations_are_html_safe = true

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  config.after_initialize do    
     require 'routing_filters.rb'
  end

  # See Rails::Configuration for more options
  ENV['RECAPTCHA_PUBLIC_KEY'] = MySociety::Config::get("RECAPTCHA_PUBLIC_KEY", 'x');
  ENV['RECAPTCHA_PRIVATE_KEY'] = MySociety::Config::get("RECAPTCHA_PRIVATE_KEY", 'x');
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

# The Rails cache is set up by the Interlock plugin to use memcached

# Domain for URLs (so can work for scripts, not just web pages)
ActionMailer::Base.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')

# So that javascript assets use full URL, so proxied admin URLs read javascript OK
if (MySociety::Config.get("DOMAIN", "") != "")
    ActionController::Base.asset_host = Proc.new { |source, request|
        if ENV["RAILS_ENV"] != "test" && request.fullpath.match(/^\/admin\//)
            MySociety::Config.get("ADMIN_PUBLIC_URL", "")
        else
            MySociety::Config.get("DOMAIN", 'localhost:3000')
        end
    }
end

# fallback locale and available locales
available_locales = MySociety::Config.get('AVAILABLE_LOCALES', '').split(/ /)
default_locale = MySociety::Config.get('DEFAULT_LOCALE', '')

FastGettext.default_available_locales = available_locales
I18n.locale = default_locale
I18n.available_locales = available_locales.map {|locale_name| locale_name.to_sym}
I18n.default_locale = default_locale

# Customise will_paginate URL generation
WillPaginate::ViewHelpers.pagination_options[:renderer] = 'WillPaginateExtension::LinkRenderer'

# Load monkey patches and other things from lib/
require 'ruby19.rb'
require 'tmail_extensions.rb'
require 'activesupport_cache_extensions.rb'
require 'timezone_fixes.rb'
require 'use_spans_for_errors.rb'
require 'make_html_4_compliant.rb'
require 'activerecord_errors_extensions.rb'
require 'willpaginate_extension.rb'
require 'sendmail_return_path.rb'
require 'tnef.rb'
require 'i18n_fixes.rb'
require 'rack_quote_monkeypatch.rb'
require 'world_foi_websites.rb'
require 'alaveteli_external_command.rb'

ExceptionNotification::Notifier.sender_address = MySociety::Config::get('EXCEPTION_NOTIFICATIONS_FROM')
ExceptionNotification::Notifier.exception_recipients = MySociety::Config::get('EXCEPTION_NOTIFICATIONS_TO')
