require File.dirname(__FILE__) + '/../commonlib/rblib/config'

# Load initial mySociety config
if ENV["RAILS_ENV"] == "test"
  MySociety::Config.set_file(File.join(File.dirname(__FILE__), '..', 'config', 'test'), true)
else
  MySociety::Config.set_file(File.join(File.dirname(__FILE__), '..', 'config', 'general'), true)
end
MySociety::Config.load_default

# Configuration values with defaults

# TODO: Make this return different values depending on the current rails environment

module AlaveteliConfiguration
  # WARNING: AlaveteliConfiguration is rendered to admin users in
  #          Admin::DebugController.
  #
  # Ensure any sensitive values match this pattern, or add to the pattern if
  # adding a new value that doesn't fit.
  mattr_accessor :sensitive_key_patterns,
                 default: /SECRET|PASSWORD|LICENSE_KEY/

  unless const_defined?(:DEFAULTS)

    # rubocop:disable Layout/LineLength
    DEFAULTS = {
      ADMIN_PASSWORD: '',
      ADMIN_USERNAME: '',
      AUTHORITY_MUST_RESPOND: true,
      AVAILABLE_LOCALES: 'en',
      BLACKHOLE_PREFIX: 'do-not-reply-to-this-address',
      BLOCK_RATE_LIMITED_IPS: false,
      BLOCK_RESTRICTED_COUNTRY_IPS: false,
      BLOCK_SPAM_ABOUT_ME_TEXT: false,
      BLOCK_SPAM_COMMENTS: false,
      BLOCK_SPAM_REQUESTS: false,
      BLOCK_SPAM_SIGNINS: false,
      BLOCK_SPAM_SIGNUPS: false,
      BLOCK_SPAM_USER_MESSAGES: false,
      BLOG_FEED: '',
      BLOG_TIMEOUT: 60,
      CACHE_FRAGMENTS: true,
      CONTACT_EMAIL: 'contact@localhost',
      CONTACT_FORM_RECAPTCHA: false,
      CONTACT_NAME: 'Alaveteli',
      DEBUG_RECORD_MEMORY: false,
      DEFAULT_LOCALE: 'en',
      DISABLE_EMERGENCY_USER: false,
      DOMAIN: 'localhost:3000',
      DONATION_URL: '',
      ENABLE_ALAVETELI_PRO: false,
      ENABLE_ANNOTATIONS: true,
      ENABLE_ANTI_SPAM: false,
      ENABLE_PROJECTS: false,
      ENABLE_PRO_PRICING: false,
      ENABLE_PRO_SELF_SERVE: false,
      ENABLE_TWO_FACTOR_AUTH: false,
      ENABLE_WIDGETS: false,
      EXCEPTION_NOTIFICATIONS_FROM: 'errors@localhost',
      EXCEPTION_NOTIFICATIONS_TO: 'user-support@localhost',
      EXTERNAL_REVIEWERS: '',
      FACEBOOK_USERNAME: '',
      FORCE_REGISTRATION_ON_NEW_REQUEST: false,
      FORCE_SSL: true,
      FORWARD_NONBOUNCE_RESPONSES_TO: 'user-support@localhost',
      FORWARD_PRO_NONBOUNCE_RESPONSES_TO: 'pro-user-support@localhost',
      FRONTPAGE_PUBLICBODY_EXAMPLES: '',
      GA_CODE: '',
      GEOIP_DATABASE: 'vendor/data/GeoLite2-Country.mmdb',
      INCOMING_EMAIL_DOMAIN: 'localhost',
      INCOMING_EMAIL_PREFIX: 'foi+',
      INCOMING_EMAIL_SECRET: 'dummysecret',
      INCOMING_EMAIL_SPAM_ACTION: false,
      INCOMING_EMAIL_SPAM_HEADER: 'X-Spam-Score',
      INCOMING_EMAIL_SPAM_THRESHOLD: false,
      ISO_COUNTRY_CODE: 'GB',
      ISO_CURRENCY_CODE: 'GBP',
      MAXMIND_LICENSE_KEY: '',
      MAX_REQUESTS_PER_USER_PER_DAY: 6,
      MINIMUM_REQUESTS_FOR_STATISTICS: 100,
      MTA_LOG_PATH: '/var/log/exim4/exim-mainlog-*',
      MTA_LOG_TYPE: 'exim',
      NEW_REQUEST_RECAPTCHA: false,
      NEW_RESPONSE_REMINDER_AFTER_DAYS: [3, 10, 24],
      OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS: '',
      POP_MAILER_ADDRESS: 'localhost',
      POP_MAILER_ENABLE_SSL: true,
      POP_MAILER_PASSWORD: '',
      POP_MAILER_PORT: 995,
      POP_MAILER_USER_NAME: '',
      PRODUCTION_MAILER_DELIVERY_METHOD: 'sendmail',
      PRODUCTION_MAILER_RETRIEVER_METHOD: 'passive',
      PRO_BATCH_AUTHORITY_LIMIT: 500,
      PRO_CONTACT_EMAIL: 'pro-contact@localhost',
      PRO_CONTACT_NAME: 'Alaveteli Professional',
      PRO_REFERRAL_COUPON: '',
      PRO_SITE_NAME: 'Alaveteli Professional',
      PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE: false,
      PUBLIC_BODY_STATISTICS_PAGE: false,
      RAW_EMAILS_LOCATION: 'files/raw_emails',
      READ_ONLY: '',
      RECAPTCHA_SECRET_KEY: 'x',
      RECAPTCHA_SITE_KEY: 'x',
      REPLY_LATE_AFTER_DAYS: 20,
      REPLY_VERY_LATE_AFTER_DAYS: 40,
      RESTRICTED_COUNTRIES: '',
      RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS: 6,
      SECRET_KEY_BASE: 'this default is insecure as code is open source, please override for live sites in config/general; this will do for local development',
      SITE_NAME: 'Alaveteli',
      SKIP_ADMIN_AUTH: false,
      SMTP_MAILER_ADDRESS: 'localhost',
      SMTP_MAILER_AUTHENTICATION: 'plain',
      SMTP_MAILER_DOMAIN: '',
      SMTP_MAILER_ENABLE_STARTTLS_AUTO: true,
      SMTP_MAILER_PASSWORD: '',
      SMTP_MAILER_PORT: 25,
      SMTP_MAILER_USER_NAME: '',
      STRIPE_NAMESPACE: '',
      STRIPE_PUBLISHABLE_KEY: '',
      STRIPE_SECRET_KEY: '',
      STRIPE_TAX_RATE: '0.20',
      STRIPE_WEBHOOK_SECRET: '',
      SURVEY_URL: '',
      THEME_BRANCH: false,
      THEME_URL: '',
      THEME_URLS: [],
      TIME_ZONE: 'UTC',
      TRACK_SENDER_EMAIL: 'contact@localhost',
      TRACK_SENDER_NAME: 'Alaveteli',
      TWITTER_USERNAME: '',
      TWITTER_WIDGET_ID: false,
      USER_CONTACT_FORM_RECAPTCHA: false,
      USE_BULLET_IN_DEVELOPMENT: false,
      USE_DEFAULT_BROWSER_LANGUAGE: true,
      USE_GHOSTSCRIPT_COMPRESSION: false,
      USE_MAILCATCHER_IN_DEVELOPMENT: true,
      USER_SIGN_IN_ACTIVITY_RETENTION_DAYS: 0,
      UTILITY_SEARCH_PATH: ['/usr/bin', '/usr/local/bin'],
      VARNISH_HOSTS: [],
      WORKING_OR_CALENDAR_DAYS: 'working'
    }
    # rubocop:enable Layout/LineLength
  end

  def self.get(key, default)
    # Don't use the `Rails.env.test?` as this has to work for external commands
    # when Rails environment isn't loaded.
    value = ENV["ALAVETELI_#{key}"] if ENV['RAILS_ENV'] == 'test'
    value || MySociety::Config.get(key, default)
  end

  def self.method_missing(name)
    key = name.to_s.upcase
    if DEFAULTS.key?(key.to_sym)
      get(key, DEFAULTS[key.to_sym])
    else
      super
    end
  end

  def self.to_sanitized_hash
    DEFAULTS.keys.each_with_object({}) do |key, memo|
      value = send(key)
      value = '[FILTERED]' if value.present? && key =~ sensitive_key_patterns
      memo[key] = value
    end
  end
end
