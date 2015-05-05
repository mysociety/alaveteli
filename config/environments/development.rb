Alaveteli::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = true

  if AlaveteliConfiguration::use_mailcatcher_in_development
    # Use mailcatcher in development
    config.action_mailer.delivery_method = :smtp # so is queued, rather than giving immediate errors
    config.action_mailer.smtp_settings = { :address => "localhost", :port => 1025 }
  else
    config.action_mailer.delivery_method = :sendmail
  end

  # Writes useful log files to debug memory leaks, of the sort where have
  # unintentionally kept references to objects, especially strings.
  # require 'memory_profiler'
  # MemoryProfiler.start :string_debug => true, :delay => 10

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  if AlaveteliConfiguration.use_rack_insight_in_development
    config.middleware.insert_before ::WhatDoTheyKnow::StripEmptySessions,
                                    Rack::Insight::App,
                                    :secret_key => AlaveteliConfiguration.rack_insight_secret_key,
                                    :database_path => AlaveteliConfiguration.rack_insight_database_path,
                                    :password => nil,
                                    :ip_masks => false
  end

  if AlaveteliConfiguration.use_bullet_in_development
    config.after_initialize do
      Bullet.enable = true
      Bullet.bullet_logger = true
      Bullet.console = true
      Bullet.add_footer = true
    end
  end
end
