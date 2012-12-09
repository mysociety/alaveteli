require File.expand_path('../boot', __FILE__)

require 'rails/all'

require File.dirname(__FILE__) + '/../lib/configuration'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Alaveteli
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the test database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Make Active Record use UTC-base instead of local time
    config.active_record.default_timezone = :utc

    # This is the timezone that times and dates are displayed in
    # Note that having set a zone, the Active Record
    # time_zone_aware_attributes flag is on, so times from models
    # will be in this time zone
    config.time_zone = ::Configuration::time_zone

    config.after_initialize do
       require 'routing_filters.rb'
    end

    config.autoload_paths << "#{Rails.root.to_s}/lib/mail_handler"

    # See Rails::Configuration for more options
    ENV['RECAPTCHA_PUBLIC_KEY'] = ::Configuration::recaptcha_public_key
    ENV['RECAPTCHA_PRIVATE_KEY'] = ::Configuration::recaptcha_private_key
  end
end
