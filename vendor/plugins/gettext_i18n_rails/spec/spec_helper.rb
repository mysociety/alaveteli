require 'rubygems'
if ENV['VERSION']
  puts "running VERSION #{ENV['VERSION']}"
  gem 'actionpack', ENV['VERSION']
  gem 'activerecord', ENV['VERSION']
  gem 'activesupport', ENV['VERSION']
  gem 'actionmailer', ENV['VERSION']
end

$LOAD_PATH << File.expand_path("../lib", File.dirname(__FILE__))

require 'active_support'
require 'active_record'
require 'action_controller'
require 'action_mailer'
require 'fast_gettext'
require 'gettext_i18n_rails'