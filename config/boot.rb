# Don't change this file. Configuration is done in config/environment.rb and config/environments/*.rb

# Hmmm, that's a bit daft - 'production' needs setting not only in the web
# server, it also needs setting in all the scripts, so a central place seems
# better. Look for a config/rails_env file, and read stuff from there if 
# it exists. Put just a line like this in there:
#   ENV['RAILS_ENV'] = 'production'
rails_env_file = File.join(File.dirname(__FILE__), 'rails_env.rb')
if File.exists?(rails_env_file)
    require rails_env_file
end

unless defined?(RAILS_ROOT)
  root_path = File.join(File.dirname(__FILE__), '..')

  unless RUBY_PLATFORM =~ /mswin32/
    require 'pathname'
    root_path = Pathname.new(root_path).cleanpath(true).to_s
  end

  RAILS_ROOT = root_path
end

unless defined?(Rails::Initializer)
  if File.directory?("#{RAILS_ROOT}/vendor/rails")
    require "#{RAILS_ROOT}/vendor/rails/railties/lib/initializer"
  else
    require 'rubygems'

    environment_without_comments = IO.readlines(File.dirname(__FILE__) + '/environment.rb').reject { |l| l =~ /^#/ }.join
    environment_without_comments =~ /[^#]RAILS_GEM_VERSION = '([\d.]+)'/
    rails_gem_version = $1

    if version = defined?(RAILS_GEM_VERSION) ? RAILS_GEM_VERSION : rails_gem_version
      # Asking for 1.1.6 will give you 1.1.6.5206, if available -- makes it easier to use beta gems
      rails_gem = Gem.cache.search('rails', "~>#{version}.0").sort_by { |g| g.version.version }.last

      if rails_gem
        require_gem "rails", "=#{rails_gem.version.version}"
        require rails_gem.full_gem_path + '/lib/initializer'
      else
        STDERR.puts %(Cannot find gem for Rails ~>#{version}.0:
    Install the missing gem with 'gem install -v=#{version} rails', or
    change environment.rb to define RAILS_GEM_VERSION with your desired version.
  )
        exit 1
      end
    else
      require_gem "rails"
      require 'initializer'
    end
  end

  Rails::Initializer.run(:set_load_path)
end
