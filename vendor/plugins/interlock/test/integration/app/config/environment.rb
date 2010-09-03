
require File.join(File.dirname(__FILE__), 'boot')
require 'action_controller'

Rails::Initializer.run do |config|
  
  if ActionController::Base.respond_to? 'session='
    config.action_controller.session = {:session_key => rand.to_s, :secret => '22cde4d5c1a61ba69a81795322cde4d5c1a61ba69a817953'}
  end
    
  #  config.to_prepare do     
  #    RAILS_DEFAULT_LOGGER.info "** interlock dependencies:"
  #    Interlock.dependencies.each do |klass, list|
  #      RAILS_DEFAULT_LOGGER.info "    #{klass}:"
  #      list.each do |key, scope|
  #        RAILS_DEFAULT_LOGGER.info "      #{key} => #{scope.inspect}"
  #      end
  #    end
  #  end
  
end

ENV['RAILS_ASSET_ID'] = rand.to_s
