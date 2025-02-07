# MySociety specific helper functions
$LOAD_PATH.push(File.join(File.dirname(__FILE__), '../../commonlib/rblib'))
# ... if these fail to include, you need the commonlib submodule from git
# (type "git submodule update --init" in the whatdotheyknow directory)

load "validate.rb"
load "config.rb"
load "format.rb"
load "debug_helpers.rb"
load "util.rb"

# Application version
ALAVETELI_VERSION = '0.45.3.1'

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
ActionMailer::Base.default_url_options[:host] = AlaveteliConfiguration.domain

# Load monkey patches and other things from lib/
require 'core_ext/warning'

require 'use_spans_for_errors.rb'
require 'world_foi_websites.rb'
require 'alaveteli_external_command.rb'
require 'html_to_pdf_converter.rb'
require 'quiet_opener.rb'
require 'attachment_to_html'
require 'health_checks'
require 'mail_handler'
require 'normalize_string'
require 'alaveteli_file_types'
require 'theme'
require 'xapian_queries'
require 'date_quarter'
require 'public_body_csv'
require 'alaveteli_text_masker'
require 'database_collation'
require 'alaveteli_geoip'
require 'default_late_calculator'
require 'analytics_event'
require 'alaveteli_gettext/fuzzy_cleaner'
require 'alaveteli_rate_limiter'
require 'alaveteli_spam_term_checker'
require 'alaveteli_pro/post_redirect_handler'
require 'user_stats'
require 'typeahead_search'
require 'alaveteli_mail_poller'
require 'safe_redirect'
require 'alaveteli_pro/metrics_report'
require 'alaveteli_pro/webhook_endpoints'

# Allow tests to be run under a non-superuser database account if required
if Rails.env.test?
  test_config = ActiveRecord::Base.configurations.find_db_config(:test).
    configuration_hash
  require 'no_constraint_disabling' unless test_config['constraint_disabling']
end
