require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # if rails_upgrade?
  #   config.asset_host = 'http://assets.example.com'
  # else
  #   config.action_controller.asset_host = 'http://assets.example.com'
  # end

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = AlaveteliConfiguration.force_ssl

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  config.log_level = ENV.fetch('LOG_LEVEL', :info)

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "alaveteli_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  if rails_upgrade?
    # Log disallowed deprecations.
    config.active_support.disallowed_deprecation = :log

    # Tell Active Support which deprecation messages to disallow.
    config.active_support.disallowed_deprecation_warnings = []
  end

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  # CUSTOM CONFIGURATION
  #
  # Always place custom environment config at the bottom of the file
  # to make Rails upgrades easier.
  # ----------------------------------------------------------------

  config.action_mailer.delivery_method = AlaveteliConfiguration.production_mailer_delivery_method.to_sym

  if AlaveteliConfiguration.production_mailer_delivery_method.to_sym == :smtp
    config.action_mailer.smtp_settings = {
      :address => AlaveteliConfiguration.smtp_mailer_address,
      :port => AlaveteliConfiguration.smtp_mailer_port,
      :domain => AlaveteliConfiguration.smtp_mailer_domain,
      :user_name => AlaveteliConfiguration.smtp_mailer_user_name,
      :password => AlaveteliConfiguration.smtp_mailer_password,
      :authentication => AlaveteliConfiguration.smtp_mailer_authentication,
      :enable_starttls_auto => AlaveteliConfiguration.smtp_mailer_enable_starttls_auto
    }
  end

  exception_notifier_prefix = '[ERROR] '
  unless AlaveteliConfiguration.domain.blank?
    exception_notifier_prefix << "[#{ AlaveteliConfiguration.domain }] "
  end

  notify_exceptions =
    AlaveteliConfiguration.exception_notifications_from.present? &&
    AlaveteliConfiguration.exception_notifications_to.present?

  if notify_exceptions
    ignored_exceptions = %w(
      ActionController::BadRequest
      ActionDispatch::Http::MimeNegotiation::InvalidType
    ) + ExceptionNotifier.ignored_exceptions

    middleware.use ExceptionNotification::Rack,
      ignore_exceptions: ignored_exceptions,
      email: {
        email_prefix: exception_notifier_prefix,
        sender_address: AlaveteliConfiguration.exception_notifications_from,
        exception_recipients: AlaveteliConfiguration.exception_notifications_to
      }
  end
end
