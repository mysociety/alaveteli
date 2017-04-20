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

# Attempt to add in Rake tasks from the theme, ignores exceptions to avoid making
# Rake unavailable because of theme script errors or THEME_URLS not being set
begin
  theme_name = File.basename(AlaveteliConfiguration::theme_urls.first, '.git')
  theme_rake_path = File.join(Rails.root,"lib","themes", theme_name, "lib", "tasks", "*.rake")

  Dir[theme_rake_path].each { |file| load(file) }
rescue
  #ignore
end
