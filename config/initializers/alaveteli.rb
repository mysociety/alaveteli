# MySociety specific helper functions
$:.push(File.join(File.dirname(__FILE__), '../../commonlib/rblib'))
# ... if these fail to include, you need the commonlib submodule from git
# (type "git submodule update --init" in the whatdotheyknow directory)

load "validate.rb"
load "config.rb"
load "format.rb"
load "debug_helpers.rb"
load "util.rb"

# Application version
ALAVETELI_VERSION = '0.12'

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# The Rails cache is set up by the Interlock plugin to use memcached

# Domain for URLs (so can work for scripts, not just web pages)
ActionMailer::Base.default_url_options[:host] = AlaveteliConfiguration::domain
# https links in emails if forcing SSL
if AlaveteliConfiguration::force_ssl
  ActionMailer::Base.default_url_options[:protocol] = "https"
end

# fallback locale and available locales
available_locales = AlaveteliConfiguration::available_locales.split(/ /)
default_locale = AlaveteliConfiguration::default_locale

FastGettext.default_available_locales = available_locales
I18n.locale = default_locale
I18n.available_locales = available_locales.map {|locale_name| locale_name.to_sym}
I18n.default_locale = default_locale

# Load monkey patches and other things from lib/
require 'ruby19.rb'
require 'activesupport_cache_extensions.rb'
require 'use_spans_for_errors.rb'
require 'activerecord_errors_extensions.rb'
require 'i18n_fixes.rb'
require 'world_foi_websites.rb'
require 'alaveteli_external_command.rb'
require 'quiet_opener.rb'
require 'mail_handler'
require 'public_body_categories'
require 'ability'
require 'normalize_string'
require 'alaveteli_file_types'

# Allow tests to be run under a non-superuser database account if required
if Rails.env == 'test' and ActiveRecord::Base.configurations['test']['constraint_disabling'] == false
  require 'no_constraint_disabling'
end
