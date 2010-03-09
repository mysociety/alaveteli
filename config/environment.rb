# Be sure to restart your web server when you modify this file.


# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# MySociety specific helper functions
$:.push(File.join(File.dirname(__FILE__), '../commonlib/rblib'))
# ... if these fail to include, you need the commonlib submodule from git
# (type "git submodule update --init" in the whatdotheyknow directory)

# ruby-ole and ruby-msg.  We use a custom ruby-msg to avoid a name conflict
$:.unshift(File.join(File.dirname(__FILE__), '../vendor/ruby-ole/lib'))
$:.unshift(File.join(File.dirname(__FILE__), '../vendor/ruby-msg/lib'))

load "validate.rb"
load "config.rb"
load "format.rb"
load "debug_helpers.rb"

Rails::Initializer.run do |config|
  # Load intial mySociety config
  MySociety::Config.set_file(File.join(config.root_path, 'config', 'general'), true)
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
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_wdtk_cookie_session',
    :secret => MySociety::Config.get("COOKIE_STORE_SESSION_SECRET", 'this default is insecure as code is open source, please override for live sites in config/general; this will do for local development')
  }
  config.action_controller.session_store = :cookie_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
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

# Include your application configuration below
ActionController::Base.cache_store = :file_store, File.join(File.dirname(__FILE__), '../cache')

# Domain for URLs (so can work for scripts, not just web pages)
ActionMailer::Base.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')

# So that javascript assets use full URL, so proxied admin URLs read javascript OK
if (MySociety::Config.get("DOMAIN", "") != "")
    ActionController::Base.asset_host = MySociety::Config.get("DOMAIN", 'localhost:3000')
end

# Load monkey patches from lib/
require 'tmail_extensions.rb'
require 'activesupport_cache_extensions.rb'
require 'public_body_categories.rb'
require 'timezone_fixes.rb'
require 'fcgi_fixes.rb'
require 'use_spans_for_errors.rb'
require 'make_html_4_compliant.rb'
require 'activerecord_errors_extensions.rb'
require 'willpaginate_hack.rb'
require 'sendmail_return_path.rb'

# XXX temp debug for SQL logging production sites
#ActiveRecord::Base.logger = Logger.new(STDOUT)

