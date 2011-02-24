require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--backtrace --color'
end
  
task :default do
  puts `rake spec VERSION=2.3.10 RSPEC_COLOR=1`
  puts `rake spec VERSION=3.0.3 RSPEC_COLOR=1`
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'gettext_i18n_rails'
    gem.summary = "Simple FastGettext Rails integration."
    gem.email = "grosser.michael@gmail.com"
    gem.homepage = "http://github.com/grosser/#{gem.name}"
    gem.authors = ["Michael Grosser"]
    gem.add_dependency 'fast_gettext'
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end
