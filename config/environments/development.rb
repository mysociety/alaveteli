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
end
