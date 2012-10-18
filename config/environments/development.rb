# Settings specified here will take precedence over those in config/environment.rb

config.log_level = :info

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.debug_rjs                         = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
config.action_mailer.perform_deliveries = false
config.action_mailer.delivery_method = :sendmail # so is queued, rather than giving immediate errors

# Writes useful log files to debug memory leaks, of the sort where have
# unintentionally kept references to objects, especially strings.
# require 'memory_profiler'
# MemoryProfiler.start :string_debug => true, :delay => 10
