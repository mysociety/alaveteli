
module Interlock
end

require 'interlock/core_extensions'
require 'interlock/config'
require 'interlock/interlock'
require 'interlock/lock'
require 'interlock/pass_through_store'
require 'interlock/action_controller'
require 'interlock/action_view'
require 'interlock/finders'
require 'interlock/active_record'

begin
  if defined?(JRUBY_VERSION)
    require 'memcache-client'
  else
    require 'memcached'
  end
rescue LoadError
end

unless ActionController::Base.perform_caching
  RAILS_DEFAULT_LOGGER.warn "** interlock warning; config.perform_caching == false"
end

Interlock::Config.run!
