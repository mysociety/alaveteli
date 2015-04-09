Alaveteli::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host                  = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  config.action_mailer.delivery_method = AlaveteliConfiguration::mailer_delivery_method.to_sym

  if AlaveteliConfiguration::mailer_delivery_method.to_sym == :smtp
    config.action_mailer.smtp_settings = {
      :address => AlaveteliConfiguration::mailer_address,
      :port => AlaveteliConfiguration.mailer_port,
      :domain => AlaveteliConfiguration.mailer_domain,
      :user_name => AlaveteliConfiguration.mailer_user_name,
      :password => AlaveteliConfiguration.mailer_password,
      :authentication => AlaveteliConfiguration.mailer_authentication,
      :enable_starttls_auto => AlaveteliConfiguration.mailer_enable_starttls_auto
    }
  end

  config.active_support.deprecation = :notify

  if !AlaveteliConfiguration.exception_notifications_from.blank? && !AlaveteliConfiguration.exception_notifications_to.blank?
    middleware.use ExceptionNotifier,
      :sender_address => AlaveteliConfiguration::exception_notifications_from,
      :exception_recipients => AlaveteliConfiguration::exception_notifications_to
  end

  require 'rack/ssl'
  if AlaveteliConfiguration::force_ssl
    config.middleware.insert_before ActionDispatch::Cookies, ::Rack::SSL
  end

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Choose the compressors to use
  # config.assets.js_compressor  = :uglifier
  # config.assets.css_compressor = :yui

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

end
