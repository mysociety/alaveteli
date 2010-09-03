
$VERBOSE = nil
require 'rubygems'
require 'test/unit'
require 'echoe'
require 'multi_rails_init'

if defined? ENV['MULTIRAILS_RAILS_VERSION']
  ENV['RAILS_GEM_VERSION'] = ENV['MULTIRAILS_RAILS_VERSION']
end

$rcov = ENV['RCOV']
require 'ruby-debug' unless $rcov

Echoe.silence do
  HERE = File.expand_path(File.dirname(__FILE__))
  $LOAD_PATH << HERE
end

require 'integration/app/config/environment'
