# -*- encoding : utf-8 -*-
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
ALAVETELI_VERSION = '0.21.0.35'

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


# Domain for URLs (so can work for scripts, not just web pages)
ActionMailer::Base.default_url_options[:host] = AlaveteliConfiguration::domain
# https links in emails if forcing SSL
if AlaveteliConfiguration::force_ssl
  ActionMailer::Base.default_url_options[:protocol] = "https"
end


# Load monkey patches and other things from lib/
require 'activesupport_cache_extensions.rb'
require 'use_spans_for_errors.rb'
require 'activerecord_errors_extensions.rb'
require 'i18n_fixes.rb'
require 'world_foi_websites.rb'
require 'alaveteli_external_command.rb'
require 'quiet_opener.rb'
require 'mail_handler'
require 'ability'
require 'normalize_string'
require 'alaveteli_file_types'
require 'alaveteli_localization'
require 'message_prominence'
require 'theme'
require 'xapian_queries'
require 'date_quarter'
require 'public_body_csv'
require 'routing_filters'
require 'alaveteli_text_masker'

AlaveteliLocalization.set_locales(AlaveteliConfiguration::available_locales,
                                  AlaveteliConfiguration::default_locale)

# Allow tests to be run under a non-superuser database account if required
if Rails.env == 'test' and ActiveRecord::Base.configurations['test']['constraint_disabling'] == false
  require 'no_constraint_disabling'
end

