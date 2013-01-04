if RUBY_VERSION.to_f >= 1.9
    # the default encoding for IO is utf-8, and we use utf-8 internally
    Encoding.default_external = Encoding.default_internal = Encoding::UTF_8
    # Suppress warning messages and require inflector to avoid iconv deprecation message
    # "iconv will be deprecated in the future, use String#encode instead." when loading
    # it as part of rails
    original_verbose, $VERBOSE = $VERBOSE, nil
    require 'active_support/inflector'
    # Activate warning messages again.
    $VERBOSE = original_verbose
end

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
ALAVETELI_VERSION = '0.6.8'

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
ActionMailer::Base.default_url_options[:host] = Configuration::domain

# So that javascript assets use full URL, so proxied admin URLs read javascript OK
if (Configuration::domain != "")
    ActionController::Base.asset_host = Proc.new { |source, request|
        if ENV["RAILS_ENV"] != "test" && request.fullpath.match(/^\/admin\//)
            Configuration::admin_public_url
        else
            Configuration::domain
        end
    }
end

# fallback locale and available locales
available_locales = Configuration::available_locales.split(/ /)
default_locale = Configuration::default_locale

FastGettext.default_available_locales = available_locales
I18n.locale = default_locale
I18n.available_locales = available_locales.map {|locale_name| locale_name.to_sym}
I18n.default_locale = default_locale

# Customise will_paginate URL generation
WillPaginate::ViewHelpers.pagination_options[:renderer] = 'WillPaginateExtension::LinkRenderer'

# Load monkey patches and other things from lib/
require 'ruby19.rb'
require 'activesupport_cache_extensions.rb'
require 'timezone_fixes.rb'
require 'use_spans_for_errors.rb'
require 'make_html_4_compliant.rb'
require 'activerecord_errors_extensions.rb'
require 'willpaginate_extension.rb'
require 'sendmail_return_path.rb'
require 'i18n_fixes.rb'
require 'rack_quote_monkeypatch.rb'
require 'world_foi_websites.rb'
require 'alaveteli_external_command.rb'
require 'quiet_opener.rb'
require 'mail_handler'
require 'public_body_categories'

if !Configuration.exception_notifications_from.blank? && !Configuration.exception_notifications_to.blank?
  ExceptionNotification::Notifier.sender_address = Configuration::exception_notifications_from
  ExceptionNotification::Notifier.exception_recipients = Configuration::exception_notifications_to
end
