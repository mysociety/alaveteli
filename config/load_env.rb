# TODO: Remove this. This is a hacky system for having a default environment.
# It looks for a config/rails_env.rb file, and reads stuff from there if
# it exists. Put just a line like this in there:
#   ENV['RAILS_ENV'] = 'production'

rails_env_file = File.expand_path('rails_env.rb', __dir__)
require rails_env_file if File.exist?(rails_env_file)
