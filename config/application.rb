# -*- encoding : utf-8 -*-
require File.expand_path('../boot', __FILE__)

require 'rails/all'

require File.dirname(__FILE__) + '/../lib/configuration'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Alaveteli
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    I18n.config.enforce_available_locales = false

    # Allow some extra tags to be whitelisted in the 'sanitize' helper method
    config.action_view.sanitized_allowed_tags = 'html', 'head', 'body', 'table', 'tr', 'td', 'style'

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

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
    config.time_zone = ::AlaveteliConfiguration::time_zone

    # Set the cache to use a memcached backend
    config.cache_store = :mem_cache_store,
      { :namespace => "#{AlaveteliConfiguration::domain}_#{RUBY_VERSION}" }
    config.action_dispatch.rack_cache = nil

    config.after_initialize do |app|
      # Add a catch-all route to force routing errors to be handled by the application,
      # rather than by middleware.
      app.routes.append { match '*path', :to => 'general#not_found', :via => [:get, :post] }
    end

    config.autoload_paths << "#{Rails.root.to_s}/app/controllers/concerns"
    config.autoload_paths << "#{Rails.root.to_s}/app/models/concerns"
    config.autoload_paths << "#{Rails.root.to_s}/lib/mail_handler"
    config.autoload_paths << "#{Rails.root.to_s}/lib/attachment_to_html"
    config.autoload_paths << "#{Rails.root.to_s}/lib/health_checks"

    # See Rails::Configuration for more options
    ENV['RECAPTCHA_PUBLIC_KEY'] = ::AlaveteliConfiguration::recaptcha_public_key
    ENV['RECAPTCHA_PRIVATE_KEY'] = ::AlaveteliConfiguration::recaptcha_private_key

    # Insert a bit of middleware code to prevent uneeded cookie setting.
    require "#{Rails.root}/lib/strip_empty_sessions"
    config.middleware.insert_before ::ActionDispatch::Cookies, StripEmptySessions, :key => '_wdtk_cookie_session', :path => "/", :httponly => true

    # Strip non-UTF-8 request parameters
    config.middleware.insert 0, Rack::UTF8Sanitizer

    # Allow the generation of full URLs in emails
    config.action_mailer.default_url_options = { :host => AlaveteliConfiguration::domain }
    if AlaveteliConfiguration::force_ssl
      config.action_mailer.default_url_options[:protocol] = "https"
    end

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Change the path that assets are served from
    # config.assets.prefix = "/assets"

    # These additional precompiled asset files are actually
    # manifests that require the real asset files:
    config.assets.precompile += ['admin.js',
                                 'profile-photos.js',
                                 'stats.js',
                                 'fancybox.css',
                                 'fancybox.js']
    # ... while these are individual files that can't easily be
    # grouped:
    config.assets.precompile += ['jquery.Jcrop.min.css',
                                 'excanvas.min.js',
                                 'select-authorities.js',
                                 'new-request.js',
                                 'fonts.css',
                                 'print.css',
                                 'admin.css',
                                 'ie6.css',
                                 'ie7.css',
                                 'bootstrap-dropdown.js',
                                 'widget.css',
                                 'responsive/print.css',
                                 'responsive/application-lte-ie7.css',
                                 'responsive/application-ie8.css']

    config.sass.load_paths += [
      "#{Gem.loaded_specs['foundation-rails'].full_gem_path}/vendor/assets/stylesheets/foundation/components",
      "#{Gem.loaded_specs['foundation-rails'].full_gem_path}/vendor/assets/stylesheets/foundation/"
    ]

  end
end
