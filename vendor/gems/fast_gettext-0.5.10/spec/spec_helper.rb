# ---- requirements
require 'rubygems'
$LOAD_PATH.unshift File.expand_path("../lib", File.dirname(__FILE__))
require 'fast_gettext'

# ---- revert to defaults
Spec::Runner.configure do |config|
  config.before :all do
    FastGettext.locale = 'de'
    FastGettext.available_locales = nil
  end
end

# ---- Helpers
def pending_it(text,&block)
  it text do
    pending(&block)
  end
end

def default_setup
  FastGettext.add_text_domain('test',:path=>File.join(File.dirname(__FILE__),'locale'))
  FastGettext.text_domain = 'test'
  FastGettext.available_locales = ['en','de']
  FastGettext.locale = 'de'
end