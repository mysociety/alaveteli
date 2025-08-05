# -*- encoding : utf-8 -*-

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# TODO: Remove this. This is a hacky system for having a default environment.
# It looks for a config/rails_env.rb file, and reads stuff from there if
# it exists. Put just a line like this in there:
#   ENV['RAILS_ENV'] = 'production'
rails_env_file = File.expand_path(File.join(File.dirname(__FILE__), 'rails_env.rb'))
if File.exist?(rails_env_file)
  require rails_env_file
end
