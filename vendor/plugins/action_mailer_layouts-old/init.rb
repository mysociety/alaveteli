begin
  require File.join(File.dirname(__FILE__), 'plugin.rb')
  ActionController::Base.logger.fatal '** Loaded layouts plugin for ActionMailer'
rescue Exception => e
  puts e.inspect
  ActionController::Base.logger.fatal e if ActionController::Base.logger
end