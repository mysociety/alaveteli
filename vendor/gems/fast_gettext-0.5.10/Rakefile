task :default => :spec
require 'spec/rake/spectask'
Spec::Rake::SpecTask.new {|t| t.spec_opts = ['--color']}

task :benchmark do
  puts "Running on #{RUBY}"
  %w[baseline ideal fast_gettext original i18n_simple].each do |bench|
    puts `ruby benchmark/#{bench}.rb`
    puts ""
  end
end

task :namespaces do
  puts `ruby benchmark/namespace/original.rb`
  puts `ruby benchmark/namespace/fast_gettext.rb`
end

begin
  require 'jeweler'
  project_name = 'fast_gettext'
  Jeweler::Tasks.new do |gem|
    gem.name = project_name
    gem.summary = "A simple, fast and threadsafe implementation of GetText"
    gem.email = "grosser.michael@gmail.com"
    gem.homepage = "http://github.com/grosser/#{project_name}"
    gem.authors = ["Michael Grosser"]
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install jeweler"
end