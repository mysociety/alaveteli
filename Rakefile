# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake/dsl_definition'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'tasks/rails'

Dir[File.join(File.dirname(__FILE__),'commonlib','rblib','tests','*.rake')].each { |file| load(file) }
