# Configuration values with defaults

# TODO: Make this return different values depending on the current rails environment

module Configuration
  DEFAULTS = {
    :ADMIN_BASE_URL => '',
    :ADMIN_PASSWORD => '',
    :ADMIN_PUBLIC_URL => '',
    :ADMIN_USERNAME => '',
    :AVAILABLE_LOCALES => '',
    :BLACKHOLE_PREFIX => 'do-not-reply-to-this-address',
    :BLOG_FEED => '',
    :CONTACT_EMAIL => 'contact@localhost',
    :CONTACT_NAME => 'Alaveteli',
    :COOKIE_STORE_SESSION_SECRET => 'this default is insecure as code is open source, please override for live sites in config/general; this will do for local development',
    :DEBUG_RECORD_MEMORY => false,
    :DEFAULT_LOCALE => '',
    :DOMAIN => 'localhost:3000',
    :EXCEPTION_NOTIFICATIONS_FROM => nil,
    :EXCEPTION_NOTIFICATIONS_TO => nil,
    :FORCE_REGISTRATION_ON_NEW_REQUEST => false,
    :FORWARD_NONBOUNCE_RESPONSES_TO => 'user-support@localhost',
    :FRONTPAGE_PUBLICBODY_EXAMPLES => '',
    :GA_CODE => '',
    :GAZE_URL => '',
    :HTML_TO_PDF_COMMAND => nil,
    :INCOMING_EMAIL_DOMAIN => 'localhost',
    :INCOMING_EMAIL_PREFIX => '',
    :INCOMING_EMAIL_SECRET => 'dummysecret',
    :ISO_COUNTRY_CODE => 'GB',
    :MAX_REQUESTS_PER_USER_PER_DAY => nil,
    :NEW_RESPONSE_REMINDER_AFTER_DAYS => [3, 10, 24],
    :OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS => '',
    :RAW_EMAILS_LOCATION => 'files/raw_emails',
    :READ_ONLY => '',
    :RECAPTCHA_PRIVATE_KEY => 'x',
    :RECAPTCHA_PUBLIC_KEY => 'x',
    :REPLY_LATE_AFTER_DAYS => 20,
    :REPLY_VERY_LATE_AFTER_DAYS => 40,
    :SITE_NAME => 'Alaveteli',
    :SKIP_ADMIN_AUTH => false,
    :SPECIAL_REPLY_VERY_LATE_AFTER_DAYS => 60,
    :THEME_URL => "",
    :THEME_URLS => [],
    :TRACK_SENDER_EMAIL => 'contact@localhost',
    :TRACK_SENDER_NAME => 'Alaveteli',
    :TWITTER_USERNAME => '',
    :USE_DEFAULT_BROWSER_LANGUAGE => true,
    :USE_GHOSTSCRIPT_COMPRESSION => nil,
    :UTILITY_SEARCH_PATH => ["/usr/bin", "/usr/local/bin"],
    :VARNISH_HOST => nil,
    :WORKING_OR_CALENDAR_DAYS => 'working',
  }

  def Configuration.method_missing(name)
    key = name.to_s.upcase
    if DEFAULTS.has_key?(key.to_sym)
      MySociety::Config.get(key, DEFAULTS[key.to_sym])
    else
      super
    end
  end
end

