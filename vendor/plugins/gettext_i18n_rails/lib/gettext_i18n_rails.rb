module GettextI18nRails
  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip
  
  extend self
end

require 'fast_gettext'
if Gem::Version.new(FastGettext::VERSION) < Gem::Version.new("0.4.8")
  raise "Please upgrade fast_gettext"
end

# include translations into all the places it needs to go...
Object.send(:include, FastGettext::Translation)

# make translations html_safe if possible and wanted
if "".respond_to?(:html_safe?)
  require 'gettext_i18n_rails/html_safe_translations'
  Object.send(:include, GettextI18nRails::HtmlSafeTranslations)
end

require 'gettext_i18n_rails/backend'
I18n.backend = GettextI18nRails::Backend.new

require 'gettext_i18n_rails/i18n_hacks'
require 'gettext_i18n_rails/active_record' if defined?(ActiveRecord)
require 'gettext_i18n_rails/action_controller' if defined?(ActionController) # so that bundle console can work in a rails project
require 'gettext_i18n_rails/railtie'
