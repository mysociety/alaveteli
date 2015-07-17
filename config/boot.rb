# -*- encoding : utf-8 -*-
require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# TODO: Remove this. This is a hacky system for having a default environment.
# It looks for a config/rails_env.rb file, and reads stuff from there if
# it exists. Put just a line like this in there:
#   ENV['RAILS_ENV'] = 'production'
rails_env_file = File.expand_path(File.join(File.dirname(__FILE__), 'rails_env.rb'))
if File.exists?(rails_env_file)
  require rails_env_file
end
