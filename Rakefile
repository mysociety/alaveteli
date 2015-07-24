# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
Alaveteli::Application.load_tasks
if Rails.env == 'test'
  Dir[Rails.root.join('commonlib','rblib','tests','*.rake')].each { |file| load(file) }
end
# Make sure the the acts_as_xapian tasks are also loaded:
Dir[Rails.root.join('lib','acts_as_xapian','tasks','*.rake')].each { |file| load(file) }
