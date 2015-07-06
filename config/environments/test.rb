# -*- encoding : utf-8 -*-
Alaveteli::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Tell ActionMailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
  if !AlaveteliConfiguration.exception_notifications_from.blank? && !AlaveteliConfiguration.exception_notifications_to.blank?
    middleware.use ExceptionNotifier,
      :sender_address => AlaveteliConfiguration::exception_notifications_from,
      :exception_recipients => AlaveteliConfiguration::exception_notifications_to
  end
end
