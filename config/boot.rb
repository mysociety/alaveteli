# -*- encoding : utf-8 -*-

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])

# TODO: Remove this. This is a hacky system for having a default environment.
# It looks for a config/rails_env.rb file, and reads stuff from there if
# it exists. Put just a line like this in there:
#   ENV['RAILS_ENV'] = 'production'
rails_env_file = File.expand_path(File.join(File.dirname(__FILE__), 'rails_env.rb'))
if File.exists?(rails_env_file)
  require rails_env_file
end

if %w{development test}.include? ENV['RAILS_ENV']
  require 'bootsnap'
  Bootsnap.setup(
    cache_dir:            'tmp/cache', # Path to your cache
    development_mode:     ENV['RAILS_ENV'] == 'development',
    load_path_cache:      true,        # Should we optimize the LOAD_PATH with a cache?
    autoload_paths_cache: true,        # Should we optimize ActiveSupport autoloads with cache?
    disable_trace:        true,        # Sets `RubyVM::InstructionSequence.compile_option = { trace_instruction: false }`
    compile_cache_iseq:   true,        # Should compile Ruby code into ISeq cache?
    compile_cache_yaml:   true         # Should compile YAML into a cache?
  )
end
