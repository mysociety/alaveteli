begin
  require 'config/initializers/session_store'
rescue LoadError
  # weird bug, when run with rake rails reports error that session
  # store is not configured, this fixes it somewhat...
end

if Rails::VERSION::MAJOR > 2
  require 'gettext_i18n_rails'
else
  #requires fast_gettext to be present.
  #We give rails a chance to install it using rake gems:install, by loading it later.
  config.after_initialize { require 'gettext_i18n_rails' }
end