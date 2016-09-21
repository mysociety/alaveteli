ENV['RAILS_ENV'] ||= 'test'

require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/rails'
require 'factory_girl_rails'
require 'capybara/rspec'
require 'shoulda/matchers'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
 config.mock_with :rspec
 config.use_transactional_fixtures = true
 config.infer_base_class_for_anonymous_controllers = false
 config.infer_spec_type_from_file_location!
 config.order = "random"
end
