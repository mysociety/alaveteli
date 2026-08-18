---
layout: page
title: Configuration
---

# Configuring Alaveteli

<p class="lead">
    You can control much of how Alaveteli looks and behaves just by
    changing the config settings.
</p>

## The general configuration file

The Alaveteli code ships with an example configuration file: `config/general.yml-example`.

As part of the [installation process]({{ page.baseurl }}/docs/installing/ ), the
example file gets copied to `config/general.yml`. You **must** edit this file to
suit your needs.

Note that the default settings for frontpage examples are designed to work with
the dummy data shipped with Alaveteli. Once you have real data, you should
certainly edit these.

Note that there are [other configuration settings and files](#other-config) too,
for specific aspects of Alaveteli.

## Config settings by topic

The following are all the configuration settings that you can change in `config/general.yml`.
When you edit this file, remember it must be in the <a href="http://yaml.org">YAML syntax</a>.
It's not complicated but &mdash; especially if you're editing a list &mdash; be careful to get the
indentation correct. If in doubt, look at the examples already in the file, and don't use tabs.


### Appearance and overall behaviour of the site:

<code><a href="#site_name">SITE_NAME</a></code>
<br> <code><a href="#domain">DOMAIN</a></code>
<br> <code><a href="#force_ssl">FORCE_SSL</a></code>
<br> <code><a href="#force_registration_on_new_request">FORCE_REGISTRATION_ON_NEW_REQUEST</a></code>
<br> <code><a href="#theme_urls">THEME_URLS</a></code>
<br> <code><a href="#theme_url">THEME_URL</a></code>
<br> <code><a href="#theme_branch">THEME_BRANCH</a></code>
<br> <code><a href="#frontpage_publicbody_examples">FRONTPAGE_PUBLICBODY_EXAMPLES</a></code>
<br> <code><a href="#public_body_statistics_page">PUBLIC_BODY_STATISTICS_PAGE</a></code>
<br> <code><a href="#minimum_requests_for_statistics">MINIMUM_REQUESTS_FOR_STATISTICS</a></code>

### Site status:

<code><a href="#read_only">READ_ONLY</a></code>
<br> <code><a href="#read_only_features">READ_ONLY_FEATURES</a></code>
<br> <code><a href="#staging_site">STAGING_SITE</a></code>

### Locale and internationalisation:

<code><a href="#iso_country_code">ISO_COUNTRY_CODE</a></code>
<br> <code><a href="#iso_currency_code">ISO_CURRENCY_CODE</a></code>
<br> <code><a href="#time_zone">TIME_ZONE</a></code>
<br> <code><a href="#available_locales">AVAILABLE_LOCALES</a></code>
<br> <code><a href="#default_locale">DEFAULT_LOCALE</a></code>
<br> <code><a href="#use_default_browser_language">USE_DEFAULT_BROWSER_LANGUAGE</a></code>

### Definition of "late":

<code><a href="#reply_late_after_days">REPLY_LATE_AFTER_DAYS</a></code>
<br> <code><a href="#reply_very_late_after_days">REPLY_VERY_LATE_AFTER_DAYS</a></code>
<br> <code><a href="#working_or_calendar_days">WORKING_OR_CALENDAR_DAYS</a></code>

### Admin access:

<code><a href="#admin_username">ADMIN_USERNAME</a></code>
<br> <code><a href="#admin_password">ADMIN_PASSWORD</a></code>
<br> <code><a href="#disable_emergency_user">DISABLE_EMERGENCY_USER</a></code>
<br> <code><a href="#skip_admin_auth">SKIP_ADMIN_AUTH</a></code>

### Email management:

<code><a href="#incoming_email_domain">INCOMING_EMAIL_DOMAIN</a></code>
<br> <code><a href="#incoming_email_prefix">INCOMING_EMAIL_PREFIX</a></code>
<br> <code><a href="#incoming_email_secret">INCOMING_EMAIL_SECRET</a></code>
<br> <code><a href="#incoming_email_spam_action">INCOMING_EMAIL_SPAM_ACTION</a></code>
<br> <code><a href="#incoming_email_spam_header">INCOMING_EMAIL_SPAM_HEADER</a></code>
<br> <code><a href="#incoming_email_spam_threshold">INCOMING_EMAIL_SPAM_THRESHOLD</a></code>
<br> <code><a href="#blackhole_prefix">BLACKHOLE_PREFIX</a></code>
<br> <code><a href="#contact_email">CONTACT_EMAIL</a></code>
<br> <code><a href="#contact_name">CONTACT_NAME</a></code>
<br> <code><a href="#track_sender_email">TRACK_SENDER_EMAIL</a></code>
<br> <code><a href="#track_sender_name">TRACK_SENDER_NAME</a></code>
<br> <code><a href="#raw_emails_location">RAW_EMAILS_LOCATION</a></code>
<br> <code><a href="#exception_notifications_from">EXCEPTION_NOTIFICATIONS_FROM</a></code>
<br> <code><a href="#exception_notifications_to">EXCEPTION_NOTIFICATIONS_TO</a></code>
<br> <code><a href="#forward_nonbounce_responses_to">FORWARD_NONBOUNCE_RESPONSES_TO</a></code>
<br> <code><a href="#mta_log_path">MTA_LOG_PATH</a></code>
<br> <code><a href="#mta_log_type">MTA_LOG_TYPE</a></code>
<br> <code><a href="#production_mailer_delivery_method">PRODUCTION_MAILER_DELIVERY_METHOD</a></code>
<br> <code><a href="#smtp_mailer_address">SMTP_MAILER_ADDRESS</a></code>
<br> <code><a href="#smtp_mailer_port">SMTP_MAILER_PORT</a></code>
<br> <code><a href="#smtp_mailer_domain">SMTP_MAILER_DOMAIN</a></code>
<br> <code><a href="#smtp_mailer_user_name">SMTP_MAILER_USER_NAME</a></code>
<br> <code><a href="#smtp_mailer_password">SMTP_MAILER_PASSWORD</a></code>
<br> <code><a href="#smtp_mailer_authentication">SMTP_MAILER_AUTHENTICATION</a></code>
<br> <code><a href="#smtp_mailer_enable_starttls_auto">SMTP_MAILER_ENABLE_STARTTLS_AUTO</a></code>
<br> <code><a href="#production_mailer_retriever_method">PRODUCTION_MAILER_RETRIEVER_METHOD</a></code>
<br> <code><a href="#pop_mailer_address">POP_MAILER_ADDRESS</a></code>
<br> <code><a href="#pop_mailer_port">POP_MAILER_PORT</a></code>
<br> <code><a href="#pop_mailer_user_name">POP_MAILER_USER_NAME</a></code>
<br> <code><a href="#pop_mailer_password">POP_MAILER_PASSWORD</a></code>
<br> <code><a href="#pop_mailer_enable_ssl">POP_MAILER_ENABLE_SSL</a></code>
<br> <code><a href="#restrict_new_responses_on_old_requests_after_months">RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS</a></code>

### General admin (keys, paths, back-end services):

<code><a href="#secret_key_base">SECRET_KEY_BASE</a></code>
<br> <code><a href="#recaptcha_site_key">RECAPTCHA_SITE_KEY</a></code>
<br> <code><a href="#recaptcha_secret_key">RECAPTCHA_SECRET_KEY</a></code>
<br> <code><a href="#usercheck_api_key">USERCHECK_API_KEY</a></code>
<br> <code><a href="#geoip_database">GEOIP_DATABASE</a></code>
<br> <code><a href="#maxmind_license_key">MAXMIND_LICENSE_KEY</a></code>
<br> <code><a href="#ga_code">GA_CODE</a></code> (GA=Google Analytics)
<br> <code><a href="#utility_search_path">UTILITY_SEARCH_PATH</a></code>
<br> <code><a href="#shared_files_path">SHARED_FILES_PATH</a></code>
<br> <code><a href="#shared_files">SHARED_FILES</a></code>
<br> <code><a href="#shared_directories">SHARED_DIRECTORIES</a></code>
<br> <code><a href="#bundle_path">BUNDLE_PATH</a></code>

### Behaviour settings and switches:

<code><a href="#new_response_reminder_after_days">NEW_RESPONSE_REMINDER_AFTER_DAYS</a></code>
<br> <code><a href="#authority_must_respond">AUTHORITY_MUST_RESPOND</a></code>
<br> <code><a href="#max_requests_per_user_per_day">MAX_REQUESTS_PER_USER_PER_DAY</a></code>
<br> <code><a href="#override_all_public_body_request_emails">OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS</a></code>
<br> <code><a href="#public_body_list_fallback_to_default_locale">PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE</a></code>
<br> <code><a href="#enable_widgets">ENABLE_WIDGETS</a></code>
<br> <code><a href="#enable_two_factor_auth">ENABLE_TWO_FACTOR_AUTH</a></code>
<br> <code><a href="#enable_annotations">ENABLE_ANNOTATIONS</a></code>
<br> <code><a href="#enable_public_annotations">ENABLE_PUBLIC_ANNOTATIONS</a></code>
<br> <code><a href="#enable_user_to_user_messaging">ENABLE_USER_TO_USER_MESSAGING</a></code>
<br> <code><a href="#survey_url">SURVEY_URL</a></code>
<br> <code><a href="#user_sign_in_activity_retention_days">USER_SIGN_IN_ACTIVITY_RETENTION_DAYS</a></code>

### External public services:

<code><a href="#blog_feed">BLOG_FEED</a></code>
<br> <code><a href="#blog_timeout">BLOG_TIMEOUT</a></code>
<br> <code><a href="#facebook_username">FACEBOOK_USERNAME</a></code>
<br> <code><a href="#twitter_username">TWITTER_USERNAME</a></code>
<br> <code><a href="#twitter_widget_id">TWITTER_WIDGET_ID</a></code>
<br> <code><a href="#donation_url">DONATION_URL</a></code>

### Development work or special cases:

<code><a href="#debug_record_memory">DEBUG_RECORD_MEMORY</a></code>
<br> <code><a href="#varnish_hosts">VARNISH_HOSTS</a></code>
<br> <code><a href="#use_mailcatcher_in_development">USE_MAILCATCHER_IN_DEVELOPMENT</a></code>
<br> <code><a href="#use_bullet_in_development">USE_BULLET_IN_DEVELOPMENT</a></code>
<br> <code><a href="#use_ghostscript_compression">USE_GHOSTSCRIPT_COMPRESSION</a></code>
<br> <code><a href="#cache_fragments">CACHE_FRAGMENTS</a></code>

### Anti-spam and abuse:

<code><a href="#enable_anti_spam">ENABLE_ANTI_SPAM</a></code>
<br> <code><a href="#block_rate_limited_ips">BLOCK_RATE_LIMITED_IPS</a></code>
<br> <code><a href="#block_restricted_country_ips">BLOCK_RESTRICTED_COUNTRY_IPS</a></code>
<br> <code><a href="#block_spam_about_me_text">BLOCK_SPAM_ABOUT_ME_TEXT</a></code>
<br> <code><a href="#block_spam_comments">BLOCK_SPAM_COMMENTS</a></code>
<br> <code><a href="#block_spam_requests">BLOCK_SPAM_REQUESTS</a></code>
<br> <code><a href="#block_spam_signins">BLOCK_SPAM_SIGNINS</a></code>
<br> <code><a href="#block_spam_signups">BLOCK_SPAM_SIGNUPS</a></code>
<br> <code><a href="#block_spam_user_messages">BLOCK_SPAM_USER_MESSAGES</a></code>
<br> <code><a href="#restricted_countries">RESTRICTED_COUNTRIES</a></code>
<br> <code><a href="#new_request_recaptcha">NEW_REQUEST_RECAPTCHA</a></code>
<br> <code><a href="#contact_form_recaptcha">CONTACT_FORM_RECAPTCHA</a></code>
<br> <code><a href="#user_contact_form_recaptcha">USER_CONTACT_FORM_RECAPTCHA</a></code>

### Alaveteli Professional:

<code><a href="#enable_alaveteli_pro">ENABLE_ALAVETELI_PRO</a></code>
<br> <code><a href="#enable_pro_pricing">ENABLE_PRO_PRICING</a></code>
<br> <code><a href="#enable_pro_self_serve">ENABLE_PRO_SELF_SERVE</a></code>
<br> <code><a href="#enable_projects">ENABLE_PROJECTS</a></code>
<br> <code><a href="#pro_contact_email">PRO_CONTACT_EMAIL</a></code>
<br> <code><a href="#pro_contact_name">PRO_CONTACT_NAME</a></code>
<br> <code><a href="#pro_site_name">PRO_SITE_NAME</a></code>
<br> <code><a href="#pro_batch_authority_limit">PRO_BATCH_AUTHORITY_LIMIT</a></code>
<br> <code><a href="#pro_referral_coupon">PRO_REFERRAL_COUPON</a></code>
<br> <code><a href="#external_reviewers">EXTERNAL_REVIEWERS</a></code>
<br> <code><a href="#forward_pro_nonbounce_responses_to">FORWARD_PRO_NONBOUNCE_RESPONSES_TO</a></code>
<br> <code><a href="#stripe_publishable_key">STRIPE_PUBLISHABLE_KEY</a></code>
<br> <code><a href="#stripe_secret_key">STRIPE_SECRET_KEY</a></code>
<br> <code><a href="#stripe_namespace">STRIPE_NAMESPACE</a></code>
<br> <code><a href="#stripe_prices">STRIPE_PRICES</a></code>
<br> <code><a href="#stripe_webhook_secret">STRIPE_WEBHOOK_SECRET</a></code>
<br> <code><a href="#stripe_tax_rate">STRIPE_TAX_RATE</a></code>


---

## All the general settings


<dl class="glossary">

  <dt>
    <a name="site_name"><code>SITE_NAME</code></a>
  </dt>
  <dd>
    <strong>SITE_NAME</strong> appears in various places throughout the site.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>SITE_NAME: 'Alaveteli'</code>
        </li>
        <li>
            <code>SITE_NAME: 'WhatDoTheyKnow'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="domain"><code>DOMAIN</code></a>
  </dt>
  <dd>
      Domain used in URLs generated by scripts (e.g. for going in some emails)
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>DOMAIN: '127.0.0.1:3000'</code>
        </li>
        <li>
            <code>DOMAIN: 'www.example.com'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="force_ssl"><code>FORCE_SSL</code></a>
  </dt>
  <dd>
      If true forces everyone (in the production environment) to use encrypted connections
      (via https) by redirecting unencrypted connections. This is <strong>highly
      recommended</strong> so that logins can't be intercepted by naughty people.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>FORCE_SSL: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="force_registration_on_new_request"><code>FORCE_REGISTRATION_ON_NEW_REQUEST</code></a>
  </dt>
  <dd>
    Does a user need to sign in to start the New Request process?
    <p>
      Alaveteli will not send a request on behalf of a user until they have
      confirmed their email address. This setting controls <em>when</em> in the
      process such confirmation is required.
    </p>
    <p>
      If <code>FORCE_REGISTRATION_ON_NEW_REQUEST</code> is false, a user who is
      not logged in can create a new request, but when they finally submit it
      they'll be invited to sign in or register; the request will not be sent
      until they have done so. That is, Alaveteli puts the confirmation of
      email address (by registering or signing in) <em>at the end</em> of the
      process. We recommend this because demanding registration right at the
      start may subtly discourage new users from making requests. If you don't
      want your site to behave in this way, set this to true.
    </p>
    <p>
      This setting does not affect the way the site behaves if the user is
      already logged in.
    </p>
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            We recommend you don't force registration at the start of the process:
            <br>
            <code>FORCE_REGISTRATION_ON_NEW_REQUEST: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme_urls"><code>THEME_URLS</code></a>
  </dt>
  <dd>
    URLs of <a href="{{ page.baseurl }}/docs/customising/themes/">themes</a> to download and use
    (when running the <code>rails-post-deploy</code> script). The earlier in the list means
    the templates have a higher priority.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <pre>
THEME_URLS:
 - 'https://github.com/mysociety/alavetelitheme.git'
</pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme_url"><code>THEME_URL</code></a>
  </dt>
  <dd>
    The URL of a single <a href="{{ page.baseurl }}/docs/customising/themes/">theme</a>
    to download and use. This is the older, deprecated single-value form; new
    installations should use
    <a href="#theme_urls"><code>THEME_URLS</code></a> instead, which accepts a
    prioritised list of themes. If set, a theme given here is installed after
    those listed in <code>THEME_URLS</code>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>THEME_URL: 'https://github.com/mysociety/alavetelitheme.git'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme_branch"><code>THEME_BRANCH</code></a>
  </dt>
  <dd>
    When <code>rails-post-deploy</code> installs the <a href="{{ page.baseurl }}/docs/customising/themes/">themes</a>,
    it will first try the branch specified by <code>THEME_BRANCH</code>, if you've
    set it to a branch name. If the branch doesn't exist (or <code>THEME_BRANCH</code>
    is false, the default) it will fall back to using a tagged version
    specific to your installed Alaveteli version, and if that doesn't exist it will
    fall back to <code>master</code>.
    <p>
        The default theme is the "Alaveteli" theme. This gets installed automatically when
        <code>rails-post-deploy</code> runs.
    </p>
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>THEME_BRANCH: 'develop'</code>
        </li>
        <li>
            <code>THEME_BRANCH: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="frontpage_publicbody_examples"><code>FRONTPAGE_PUBLICBODY_EXAMPLES</code></a>
  </dt>
  <dd>
    Specify which public bodies you want to be listed as examples on the home page,
    using their <code>short_names</code>.
    If you want more than one, separate them with semicolons.
    Comment this out if you want this to be auto-generated.
    <p>
      <strong>Warning</strong>: this is slow &mdash; don't use in production!
    </p>
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>FRONTPAGE_PUBLICBODY_EXAMPLES: 'tgq'</code>
        </li>
        <li>
            <code>FRONTPAGE_PUBLICBODY_EXAMPLES: 'tgq;foo;bar'</code>
        </li>
        <li>
            <code># FRONTPAGE_PUBLICBODY_EXAMPLES: </code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="public_body_statistics_page"><code>PUBLIC_BODY_STATISTICS_PAGE</code></a> &amp;
    <a name="minimum_requests_for_statistics"><code>MINIMUM_REQUESTS_FOR_STATISTICS</code></a>
  </dt>
  <dd>
      If <strong>PUBLIC_BODY_STATISTICS_PAGE</strong> is set to true, Alaveteli will make a
      page of statistics on the performance of public bodies (which you can see at
      <code>/body_statistics</code>).
      The page will only consider public bodies that have had at least the number of requests
      set by <strong>MINIMUM_REQUESTS_FOR_STATISTICS</strong>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PUBLIC_BODY_STATISTICS_PAGE: false</code>
        </li>
        <li>
            <code>MINIMUM_REQUESTS_FOR_STATISTICS: 100</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="read_only"><code>READ_ONLY</code></a>
  </dt>
  <dd>
      If present, <strong>READ_ONLY</strong> puts the site in read-only mode,
      and uses the text as reason (whole paragraph). Please use a read-only database
      user as well, as it only checks in a few obvious places.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            Typically, you do <strong>not</strong> want to run your site in
            read-only mode &mdash; so set <strong>READ_ONLY</strong> to be
            an empty string.
            <br>
            <code>
                READ_ONLY: ''
            </code>
        </li>
        <li>
            <code>
                READ_ONLY: 'The site is not currently accepting requests while we move the server.'
            </code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="read_only_features"><code>READ_ONLY_FEATURES</code></a>
  </dt>
  <dd>
      Granular read-only control for specific features. This lets you disable
      specific functionality without putting the entire site into read-only mode
      with <a href="#read_only"><code>READ_ONLY</code></a>.
      <p>The available features are:</p>
      <ul>
        <li><code>annotations</code> blocks annotations on requests</li>
        <li><code>classifications</code> blocks request status classifications</li>
        <li><code>followups</code> blocks followup messages on requests</li>
        <li><code>requests</code> blocks new FOI requests</li>
        <li><code>signups</code> blocks new user registration</li>
      </ul>
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            Block only new requests:
            <br>
            <code>READ_ONLY_FEATURES: ['requests']</code>
        </li>
        <li>
            Block new requests and annotations:
            <br>
            <code>READ_ONLY_FEATURES: ['requests', 'annotations']</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="staging_site"><code>STAGING_SITE</code></a>
  </dt>
  <dd>
     Is this a
     <a href="{{ page.baseurl }}/docs/glossary/#staging" class="glossary__link">staging</a> or
     <a href="{{ page.baseurl }}/docs/glossary/#development" class="glossary__link">development</a> site?
     If not, it's a live <a href="{{ page.baseurl }}/docs/glossary/#production" class="glossary__link">production</a>
     site. This setting controls whether or not the <code>rails-post-deploy</code>
     script will create the file <code>config/rails_env.rb</code> file to force
     Rails into production environment.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            For staging or development:
            <p>
              <code>STAGING_SITE: 1</code>
            </p>
        </li>
        <li>
            For production:
            <p>
              <code>STAGING_SITE: 0</code>
            </p>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="iso_country_code"><code>ISO_COUNTRY_CODE</code></a>
  </dt>
  <dd>
    The <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2">ISO country code</a>
    of the country in which your Alaveteli site is deployed.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ISO_COUNTRY_CODE: GB</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="iso_currency_code"><code>ISO_CURRENCY_CODE</code></a>
  </dt>
  <dd>
    The <a href="https://en.wikipedia.org/wiki/ISO_4217#Active_codes">ISO currency code</a>
    of the currency in which Alaveteli Professional subscription costs are
    displayed. This does not affect the currency the plans are set up in, so it
    should match what is configured at
    <a href="https://stripe.com/docs/currencies">Stripe.com</a>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ISO_CURRENCY_CODE: GBP</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="time_zone"><code>TIME_ZONE</code></a>
  </dt>
  <dd>
   This is the <a href="http://en.wikipedia.org/wiki/List_of_tz_database_time_zones">timezone</a>
   that Alaveteli usese to display times and dates.
   If not set, defaults to UTC.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>TIME_ZONE: Australia/Sydney</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="available_locales"><code>AVAILABLE_LOCALES</code></a> &
    <a name="default_locale"><code>DEFAULT_LOCALE</code></a>
  </dt>
  <dd>
    <strong>AVAILABLE_LOCALES</strong> lists all the locales you want your site to support.
    If there is more than one, use spaces betwween the entries.
    Nominate one of these locales as the default with <strong>DEFAULT_LOCALE</strong>.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>AVAILABLE_LOCALES: 'en es'</code>
        </li>
        <li>
            <code>DEFAULT_LOCALE: 'en'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="use_default_browser_language"><code>USE_DEFAULT_BROWSER_LANGUAGE</code></a>
  </dt>
  <dd>
      Should Alaveteli try to use the default language of the user's browser?
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>USE_DEFAULT_BROWSER_LANGUAGE: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="reply_late_after_days"><code>REPLY_LATE_AFTER_DAYS</code></a><br>
    <a name="reply_very_late_after_days"><code>REPLY_VERY_LATE_AFTER_DAYS</code></a><br>
    <a name="working_or_calendar_days"><code>WORKING_OR_CALENDAR_DAYS</code></a>
  </dt>
  <dd>
        The <strong>REPLY...AFTER_DAYS</strong> settings define how many days must have
        passed before an answer to a request is officially <em>late</em>.
        The <strong>WORKING_OR_CALENDAR_DAYS</strong> setting can be either "working" (the default)
        or "calendar", and determines which days are counted.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>REPLY_LATE_AFTER_DAYS: 20</code>
        </li>
        <li>
            <code>REPLY_VERY_LATE_AFTER_DAYS: 40</code>
        </li>
        <li>
          <code>WORKING_OR_CALENDAR_DAYS: working</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="admin_username"><code>ADMIN_USERNAME</code></a>
    &amp;
    <a name="admin_password"><code>ADMIN_PASSWORD</code></a>
    <br>
    <a name="disable_emergency_user"><code>DISABLE_EMERGENCY_USER</code></a>
  </dt>
  <dd>
      Details for the
      <a href="{{ page.baseurl }}/docs/glossary/#emergency" class="glossary__link">emergency user</a>.
      <p>
        This is useful for creating the initial admin users for your site:
        <ul>
          <li>Create a new user (using regular sign up on the site)</li>
          <li>Log in as the emergency user</li>
          <li>Promote the new account</li>
          <li>Disable the emergency user</li>
        </ul>
      </p>
      <p>
        For details of this process, see
        <a href="{{ page.baseurl }}/docs/installing/next_steps/#create-an-admin-account">creating
          a admin account</a>.
      </p>
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>ADMIN_USERNAME: 'adminxxxx'</code>
        </li>
        <li>
            <code>ADMIN_PASSWORD: 'passwordx'</code>
        </li>
        <li>
            <code>DISABLE_EMERGENCY_USER: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="skip_admin_auth"><code>SKIP_ADMIN_AUTH</code></a>
  </dt>
  <dd>
      Set this to true, and the admin interface will be available to anonymous users.
      Obviously, you should not set this to be true in production environments.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SKIP_ADMIN_AUTH: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="incoming_email_domain"><code>INCOMING_EMAIL_DOMAIN</code></a>
  </dt>
  <dd>
    Your email domain for incoming mail.  See also  <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">How Alaveteli handles email</a>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>INCOMING_EMAIL_DOMAIN: 'localhost'</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_DOMAIN: 'foifa.com'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="incoming_email_prefix"><code>INCOMING_EMAIL_PREFIX</code></a>
  </dt>
  <dd>
      An optional prefix to help you distinguish FOI requests.  See also  <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">How Alaveteli handles email</a>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>INCOMING_EMAIL_PREFIX: ''</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_PREFIX: 'foi+'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="incoming_email_secret"><code>INCOMING_EMAIL_SECRET</code></a>
  </dt>
  <dd>
     Used for hash in request email address.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>INCOMING_EMAIL_SECRET: '11ae 4e3b 70ff c001 3682 4a51 e86d ef5f'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="incoming_email_spam_action"><code>INCOMING_EMAIL_SPAM_ACTION</code></a>
    <a name="incoming_email_spam_header"><code>INCOMING_EMAIL_SPAM_HEADER</code></a>
      &amp;
    <a name="incoming_email_spam_threshold"><code>INCOMING_EMAIL_SPAM_THRESHOLD</code></a>
  </dt>
  <dd>

    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.22.2.0
      </p>
    </div>

    <p>
      Filter incoming mail that looks like spam. Spam can be redirected to the
      holding pen or discarded.
    </p>

    <p>
      If you filter incoming emails through a spam detector like SpamAssassin,
      you can configure Alaveteli to filter messages with a high spam score.
    </p>

    <p>
      This feature requires the messages to contain a header with a numeric
      spam score, and <strong>INCOMING_EMAIL_SPAM_ACTION</strong>,
      <strong>INCOMING_EMAIL_SPAM_HEADER</strong> and
      <strong>INCOMING_EMAIL_SPAM_THRESHOLD</strong> to be configured before
      the filtering will take effect.
    </p>

    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>INCOMING_EMAIL_SPAM_ACTION: 'discard'</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_SPAM_ACTION: 'holding_pen'</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_SPAM_ACTION: 'false'</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_SPAM_HEADER: 'X-mySociety-Spam-Score'</code>
        </li>
        <li>
            <code>INCOMING_EMAIL_SPAM_THRESHOLD: 20</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="blackhole_prefix"><code>BLACKHOLE_PREFIX</code></a>
  </dt>
  <dd>
      Used as envelope from at the incoming email domain for cases where you don't care about failure.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLACKHOLE_PREFIX: 'do-not-reply-to-this-address'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="contact_email"><code>CONTACT_EMAIL</code></a>
      &amp;
    <a name="contact_name"><code>CONTACT_NAME</code></a>
  </dt>
  <dd>
      Email "from" details.  See also  <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">How Alaveteli handles email</a>.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>CONTACT_EMAIL: 'team@example.com'</code>
        </li>
        <li>
            <code>CONTACT_NAME: 'Alaveteli Webmaster'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="track_sender_email"><code>TRACK_SENDER_EMAIL</code></a> &amp;
    <a name="track_sender_name"><code>TRACK_SENDER_NAME</code></a>
  </dt>
  <dd>
      Email "from" details for track messages.  See also  <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">How Alaveteli handles email</a>.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>TRACK_SENDER_EMAIL: 'alaveteli@example.com'</code>
        </li>
        <li>
            <code>TRACK_SENDER_NAME: 'Alaveteli Webmaster'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="raw_emails_location"><code>RAW_EMAILS_LOCATION</code></a>
  </dt>
  <dd>
      Where the raw incoming email data gets stored.
      <strong>Make sure you back this up!</strong>
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>RAW_EMAILS_LOCATION: 'files/raw_emails'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="exception_notifications_from"><code>EXCEPTION_NOTIFICATIONS_FROM</code></a> &amp;
    <a name="exception_notifications_to"><code>EXCEPTION_NOTIFICATIONS_TO</code></a>
  </dt>
  <dd>
      Email address(es) used for sending exception notifications.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <pre>
EXCEPTION_NOTIFICATIONS_FROM: do-not-reply-to-this-address@example.com

EXCEPTION_NOTIFICATIONS_TO:
 - robin@example.com
 - seb@example.com
</pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="forward_nonbounce_responses_to"><code>FORWARD_NONBOUNCE_RESPONSES_TO</code></a>
  </dt>
  <dd>
     The email address to which non-bounce responses should be forwarded. See also  <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">How Alaveteli handles email</a>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>FORWARD_NONBOUNCE_RESPONSES_TO: user-support@example.com</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="mta_log_path"><code>MTA_LOG_PATH</code></a>
  </dt>
  <dd>
      Path to your exim or postfix log files that will get sucked up
      by <code>script/load-mail-server-logs</code>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>MTA_LOG_PATH: '/var/log/exim4/exim-mainlog-*'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="mta_log_type"><code>MTA_LOG_TYPE</code></a>
  </dt>
  <dd>
      Are you using "exim" or "postfix" for your Mail Transfer Agent (MTA)?

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>MTA_LOG_TYPE: "exim"</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="production_mailer_delivery_method"><code>PRODUCTION_MAILER
_DELIVERY_METHOD</code></a>
  </dt>
  <dd>
      What delivery method is being
      used for outgoing emails in production? The default value is
      <code>sendmail</code>, but there is experimental support for <code>smtp</code>.
      If you want to use an external SMTP server to send email, then you will
also need to include SMTP configuration settings:
<a
href="#smtp_mailer_address">SMTP_MAILER_ADDRESS</a>, <a
href="#smtp_mailer_port">SMTP_MAILER_PORT</a>, <a
href="#smtp_mailer_domain">SMTP_MAILER_DOMAIN</a>, <a
href="#smtp_mailer_user_name">SMTP_MAILER_USER_NAME</a>,       <a
href="#smtp_mailer_password">SMTP_MAILER_PASSWORD</a>, <a
href="#smtp_mailer_authentication">SMTP_MAILER_AUTHENTICATION</a> and <a
href="#smtp_mailer_enable_starttls_auto">SMTP_MAILER_ENABLE_STARTTLS_AUTO</a>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PRODUCTION_MAILER_DELIVERY_METHOD: "sendmail"</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="smtp_mailer_address">SMTP_MAILER_ADDRESS</a></code>
  </dt>
  <dd>
      Set this to <code>localhost</code> to use a local SMTP server, or the remote address of your
      SMTP server. Only required if <a href="#production_mailer_delivery_method"><code>PRODUCTION_MAILER_DELIVERY_METHOD</code></a> is set to <code>smtp</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SMTP_MAILER_ADDRESS: "smtp.gmail.com"</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="smtp_mailer_port">SMTP_MAILER_PORT</a></code>
  </dt>
  <dd>
    On the off chance that your mail server doesn't run on port 25, you can change it. Only required if <a href="#production_mailer_delivery_method"><code>PRODUCTION_MAILER_DELIVERY_METHOD</code></a> is set to <code>smtp</code>.


    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SMTP_MAILER_PORT: 25</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="smtp_mailer_domain">SMTP_MAILER_DOMAIN</a></code>
  </dt>
  <dd>
    If you need to specify a HELO domain, you can do it here. Only required if <a href="#production_mailer_delivery_method"><code>PRODUCTION_MAILER_DELIVERY_METHOD</code></a> is set to <code>smtp</code>.


    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SMTP_MAILER_DOMAIN: gmail.com</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="smtp_mailer_user_name">SMTP_MAILER_USER_NAME</a></code>
  </dt>
  <dd>
    If your mail server requires authentication, set the username in this setting. Only required if <a href="#production_mailer_delivery_method"><code>PRODUCTION_MAILER_DELIVERY_METHOD</code></a> is set to <code>smtp</code>.


    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SMTP_MAILER_USER_NAME: alaveteli</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="smtp_mailer_password">SMTP_MAILER_PASSWORD</a></code>
  </dt>
  <dd>
    If your mail server requires authentication, set the password in this setting. Only required if <a href="#production_mailer_delivery_method"><code>PRODUCTION_MAILER_DELIVERY_METHOD</code></a> is set to <code>smtp</code>.


    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SMTP_MAILER_PASSWORD: supersecretpassword</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="smtp_mailer_authentication">SMTP_MAILER_AUTHENTICATION</a></code>
  </dt>
  <dd>
    If your mail server requires authentication, you need to specify the authentication type here. This is one of <code>plain</code>, <code>login</code>, <code>cram_md5</code>. Only required if <a href="#production_mailer_delivery_method"><code>PRODUCTION_MAILER_DELIVERY_METHOD</code></a> is set to <code>smtp</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SMTP_MAILER_AUTHENTICATION: plain</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="smtp_mailer_enable_starttls_auto">SMTP_MAILER_ENABLE_STARTTLS_AUTO</a></code>
  </dt>
  <dd>
   Set this to false if there is a problem with your server certificate that you cannot resolve. Only required if <a href="#production_mailer_delivery_method"><code>PRODUCTION_MAILER_DELIVERY_METHOD</code></a> is set to <code>smtp</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SMTP_MAILER_ENABLE_STARTTLS_AUTO: true</code>
        </li>
      </ul>
    </div>
  </dd>


  <dt>
    <a name="production_mailer_retriever_method"><code>PRODUCTION_MAILER_RETRIEVER_METHOD</code></a>
  </dt>
  <dd>
      <div class="attention-box">
        <p>
          Introduced in Alaveteli 0.30.0.0
        </p>
      </div>
      <p>What retrieval method is being used for incoming emails in production?</p>
      <p>
      The default value is <code>passive</code> - incoming emails must be piped into the
      application via the <code>mailin</code> script. There is
      experimental support for polling a <code>POP3</code> server for messages,
      if <code>PRODUCTION_MAILER_RETRIEVER_METHOD</code> is set to <code>pop</code>.
      </p>
      <p>For some guidance on considerations and setup for running a POP
      service, see <a href="{{ page.baseurl }}/docs/installing/email#how-alaveteli-handles-email">
      how Alaveteli handles email</a>.
      </p>
      <p>
      If you want to use an external POP3 server to receive email, then you
      will also need to include POP configuration settings:

      <a href="#pop_mailer_address">POP_MAILER_ADDRESS</a>,
      <a href="#pop_mailer_port">POP_MAILER_PORT</a>,
      <a href="#pop_mailer_user_name">POP_MAILER_USER_NAME</a>,
      <a href="#pop_mailer_password">POP_MAILER_PASSWORD</a> and
      <a href="#pop_mailer_enable_ssl">POP_MAILER_ENABLE_SSL</a>.
      </p>

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PRODUCTION_MAILER_RETRIEVER_METHOD: "passive"</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="pop_mailer_address">POP_MAILER_ADDRESS</a></code>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.30.0.0
      </p>
    </div>
   Set this to the address of the <code>POP3</code> server you want to poll for incoming
   messages. Only required if <a href="#production_mailer_retriever_method"><code>PRODUCTION_MAILER_RETRIEVER_METHOD</code></a> is set to <code>pop</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>POP_MAILER_ADDRESS: 'localhost'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="pop_mailer_port">POP_MAILER_PORT</a></code>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.30.0.0
      </p>
    </div>
    The port that your <code>POP3</code> server accepts connections on.
    Only required if <a href="#production_mailer_retriever_method"><code>PRODUCTION_MAILER_RETRIEVER_METHOD</code></a> is set to <code>pop</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>POP_MAILER_PORT: 995</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="pop_mailer_user_name">POP_MAILER_USER_NAME</a></code>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.30.0.0
      </p>
    </div>
    Set the username of the account user to connect to the POP server.
    Only required if <a href="#production_mailer_retriever_method"><code>PRODUCTION_MAILER_RETRIEVER_METHOD</code></a> is set to <code>pop</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>POP_MAILER_USER_NAME: 'jane322'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="pop_mailer_password">POP_MAILER_PASSWORD</a></code>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.30.0.0
      </p>
    </div>
    Set the password of the account user to connect to the POP server.
    Only required if <a href="#production_mailer_retriever_method"><code>PRODUCTION_MAILER_RETRIEVER_METHOD</code></a> is set to <code>pop</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>POP_MAILER_PASSWORD: 'supersecretpassword'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <code><a name="pop_mailer_enable_ssl">POP_MAILER_ENABLE_SSL</a></code>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.30.0.0
      </p>
    </div>
   Should Alaveteli use SSL when connecting to the <code>POP3</code> server used?
   Only required if <a href="#production_mailer_retriever_method"><code>PRODUCTION_MAILER_RETRIEVER_METHOD</code></a> is set to <code>pop</code>.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>POP_MAILER_ENABLE_SSL: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="restrict_new_responses_on_old_requests_after_months"><code>RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS</code></a><br>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.23.0.0
      </p>
    </div>

    Number of months after which to start restricting new responses to requests.
    When a request has not been updated after <strong>RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS</strong>, allow_new_responses_from is set to <code>'authority_only'</code>. After <strong>RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS &times; 4</strong> , allow_new_responses_from is set to <code>'nobody'</code>.

    <p>
      For details of this process, see
      <a href="{{ page.baseurl }}/docs/running/requests/#old-requests-by-default-6-months-without-activity">old requests</a>.
    </p>
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS: 3</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="secret_key_base"><code>SECRET_KEY_BASE</code></a>
  </dt>
  <dd>
     Used as the base from which Rails generates and verifies signed cookies
     (among other things). Make it long and random; you can generate a suitable
     value with <code>rake secret</code>. The built-in default is insecure
     because the code is open source, so you <strong>must</strong> override it
     for live sites.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SECRET_KEY_BASE: 'uIngVC238Jn9NsaQizMNf89pliYmDBFugPjHS2JJmzOp8'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
      <a name="recaptcha_site_key"><code>RECAPTCHA_SITE_KEY</code></a> &amp;
      <a name="recaptcha_secret_key"><code>RECAPTCHA_SECRET_KEY</code></a>
  </dt>
  <dd>
     Recaptcha, for detecting humans. Get keys here:
     <a href="https://www.google.com/recaptcha">https://www.google.com/recaptcha</a>.
     Currently Alaveteli requires a reCAPTCHA v2 Checkbox key.

    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>RECAPTCHA_SITE_KEY: '7HoPjGBBBBBBBBBkmj78HF9PjjaisQ893'</code><br>
            (Called <small><code>RECAPTCHA_PUBLIC_KEY</code></small> before release 0.32)
        </li>
        <li>
            <code>RECAPTCHA_SECRET_KEY: '7HjPjGBBBBBCBBBpuTy8a33sgnGG7A'</code><br>
            (Called <small><code>RECAPTCHA_PRIVATE_KEY</code></small> before release 0.32)
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="usercheck_api_key"><code>USERCHECK_API_KEY</code></a>
  </dt>
  <dd>
      API key for <a href="https://www.usercheck.com">UserCheck.com</a>, used to
      detect spammy sign-ups. If set, Alaveteli checks the email domain of each
      new user account against the UserCheck API and adds to the account's spam
      score if the domain is a disposable email domain (default score 20), a
      relay or forwarding domain (10), or has invalid MX records (5). If the key
      is not set, the checks don't run at all. Only the email
      <strong>domain</strong> is sent to the API &mdash; never the full email
      address &mdash; and results are cached for 28 days per domain, so a domain
      that has already been seen generates no further requests. If the API is
      unavailable, the checks silently score nothing and Alaveteli falls back to
      its existing behaviour. The default scores can be changed via
      <code>score_mappings</code> in
      <a href="#other-config"><code>config/user_spam_scorer.yml</code></a>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>USERCHECK_API_KEY: 'xxxxxxxxxxxxxxxxxxxxxxxx'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_anti_spam"><code>ENABLE_ANTI_SPAM</code></a>
  </dt>
  <dd>
    If set to true, Alaveteli enforces a set of extra restrictions to combat
    spam requests, annotations and profile content. This includes the ability to
    restrict IP addresses from some countries from performing some actions (see
    <a href="#restricted_countries"><code>RESTRICTED_COUNTRIES</code></a>),
    showing a reCAPTCHA on new request submission, and preventing the submission
    of requests, annotations and profile text matching a set of spam content
    patterns.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_ANTI_SPAM: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_rate_limited_ips"><code>BLOCK_RATE_LIMITED_IPS</code></a>
  </dt>
  <dd>
    Prevent user signups if several signup attempts from the same IP address are
    made in quick succession.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_RATE_LIMITED_IPS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_restricted_country_ips"><code>BLOCK_RESTRICTED_COUNTRY_IPS</code></a>
  </dt>
  <dd>
    Prevent users signing up and making requests if their IP address originates
    in one of the
    <a href="#restricted_countries"><code>RESTRICTED_COUNTRIES</code></a>.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_RESTRICTED_COUNTRY_IPS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_spam_about_me_text"><code>BLOCK_SPAM_ABOUT_ME_TEXT</code></a>
  </dt>
  <dd>
    Prevent users submitting spam as their "About me" profile text.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_SPAM_ABOUT_ME_TEXT: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_spam_comments"><code>BLOCK_SPAM_COMMENTS</code></a>
  </dt>
  <dd>
    Prevent users submitting comments that appear to be spam.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_SPAM_COMMENTS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_spam_requests"><code>BLOCK_SPAM_REQUESTS</code></a>
  </dt>
  <dd>
    Prevent users submitting requests that appear to be spam.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_SPAM_REQUESTS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_spam_signins"><code>BLOCK_SPAM_SIGNINS</code></a>
  </dt>
  <dd>
    Prevent user signins from spam email domains or names which appear to be spam.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_SPAM_SIGNINS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_spam_signups"><code>BLOCK_SPAM_SIGNUPS</code></a>
  </dt>
  <dd>
    Prevent user signups from spam email domains or names which appear to be spam.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_SPAM_SIGNUPS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="block_spam_user_messages"><code>BLOCK_SPAM_USER_MESSAGES</code></a>
  </dt>
  <dd>
    Prevent users submitting user to user messages that appear to be spam.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOCK_SPAM_USER_MESSAGES: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="restricted_countries"><code>RESTRICTED_COUNTRIES</code></a>
  </dt>
  <dd>
    Restrict IP addresses from some countries from performing some actions. If
    set, requests from IP addresses in the countries specified are prevented from
    making new requests on the site. Country codes can be prefixed with
    <code>!</code> to invert the list from restricted to permitted (that is, to
    allow requests only from the specified countries). Given as a string of
    space-separated uppercase ISO Alpha-2 codes.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            Block GB and ES:
            <br>
            <code>RESTRICTED_COUNTRIES: 'GB ES'</code>
        </li>
        <li>
            Only allow GB and ES:
            <br>
            <code>RESTRICTED_COUNTRIES: '!GB !ES'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="new_request_recaptcha"><code>NEW_REQUEST_RECAPTCHA</code></a>
  </dt>
  <dd>
    Show a reCAPTCHA on the new request submission form if a user is not signed
    in or not marked as confirmed not spam. Requires
    <a href="#recaptcha_site_key"><code>RECAPTCHA_SITE_KEY</code></a> and
    <a href="#recaptcha_secret_key"><code>RECAPTCHA_SECRET_KEY</code></a> to be set.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>NEW_REQUEST_RECAPTCHA: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="contact_form_recaptcha"><code>CONTACT_FORM_RECAPTCHA</code></a>
  </dt>
  <dd>
    Show a reCAPTCHA on the contact form to discourage spammers. Requires
    <a href="#recaptcha_site_key"><code>RECAPTCHA_SITE_KEY</code></a> and
    <a href="#recaptcha_secret_key"><code>RECAPTCHA_SECRET_KEY</code></a> to be
    set. You also need to add the reCAPTCHA tags to
    <code>help/_contact_form.html.erb</code> in your theme (just above the submit
    button works best):
<pre>
&lt;% if @recaptcha_required %&gt;
  &lt;%= recaptcha_tags %&gt;&lt;br /&gt;
&lt;% end %&gt;
</pre>
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>CONTACT_FORM_RECAPTCHA: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="user_contact_form_recaptcha"><code>USER_CONTACT_FORM_RECAPTCHA</code></a>
  </dt>
  <dd>
    Show a reCAPTCHA on the user to user contact form to discourage spammers.
    Requires <a href="#recaptcha_site_key"><code>RECAPTCHA_SITE_KEY</code></a> and
    <a href="#recaptcha_secret_key"><code>RECAPTCHA_SECRET_KEY</code></a> to be set.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>USER_CONTACT_FORM_RECAPTCHA: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="geoip_database"><code>GEOIP_DATABASE</code></a>
  </dt>
  <dd>
      Alaveteli uses a GeoIP database to determine the country from the IP address
      of an HTTP request to the site (this lets us suggest an Alaveteli in the user's
      country if one exists). You shouldn't need to change this if you have the
      <code>geoip-database</code> package installed as specified in the
      <code>config/packages</code> files. You <strong>must</strong> set
      <code><a href="#maxmind_license_key">MAXMIND_LICENSE_KEY</a></code> with
      this setting.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>GEOIP_DATABASE: vendor/data/GeoLite2-Country.mmdb</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="maxmind_license_key"><code>MAXMIND_LICENSE_KEY</code></a>
  </dt>
  <dd>
      MaxMind requires a free licence key to download the GeoLite2 databases
      used by <a href="#geoip_database"><code>GEOIP_DATABASE</code></a>. You
      <strong>must</strong> set this if you want Alaveteli to download and update
      the GeoIP database. See
      <a href="https://blog.maxmind.com/2019/12/18/significant-changes-to-accessing-and-using-geolite2-databases/">MaxMind's
      announcement</a> for details.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>MAXMIND_LICENSE_KEY: ''</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="ga_code"><code>GA_CODE</code> (GA=Google Analytics)</a>
  </dt>
  <dd>
      Adding a value here will enable Google Analytics on all non-admin pages for non-admin users.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>GA_CODE: ''</code>
        </li>
        <li>
            <code>GA_CODE: 'AB-8222142-14'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="utility_search_path"><code>UTILITY_SEARCH_PATH</code></a>
  </dt>
  <dd>
      Search path for external command-line utilities (such as pdftk, unrtf).
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>UTILITY_SEARCH_PATH: ["/usr/bin", "/usr/local/bin"]</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="shared_files_path"><code>SHARED_FILES_PATH</code></a>
  </dt>
  <dd>
     In some deployments of Alaveteli you may wish to install each newly
     deployed version alongside the previous ones, in which case certain
     files and resources should be shared between these installations.
     For example, the <code>files</code> directory, the <code>cache</code> directory and the
     generated graphs such as <code>public/foi-live-creation.png</code>.  If you're
     installing Alaveteli in such a setup then set <strong>SHARED_FILES_PATH</strong> to
     the directory you're keeping these files under.  Otherwise, leave it blank.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SHARED_FILES_PATH: ''</code> <!-- TODO specific example -->
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="shared_files"><code>SHARED_FILES</code></a> &
    <a name="shared_directories"><code>SHARED_DIRECTORIES</code></a>
  </dt>
  <dd>
     If you have <strong>SHARED_FILES_PATH</strong> set, then these options list the files
     and directories that are shared; i.e. those to which the deploy scripts
     should create symlinks from the repository.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <pre>
SHARED_FILES:
 - config/database.yml
 - config/general.yml
 - config/sidekiq.yml
 - config/storage.yml
 - config/rails_env.rb
 - config/httpd.conf
 - public/foi-live-creation.png
 - public/foi-user-use.png
 - config/aliases
            </pre>
        </li>
        <li>
            <pre>
SHARED_DIRECTORIES:
 - files/
 - cache/
 - lib/acts_as_xapian/xapiandbs/
 - log/
 - storage/
 - tmp/pids
 - vendor/bundle
 - public/assets
            </pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="bundle_path"><code>BUNDLE_PATH</code></a>
  </dt>
  <dd>
     The path that Bundler installs gems into. The deploy scripts read this
     value (via <code>bin/config</code>) and run
     <code>bundle config set --local path</code> with it, so gems are installed
     there rather than system-wide. It is used by the deployment tooling, not
     read by the running application. If it is not set, it defaults to
     <code>vendor/bundle</code>.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>BUNDLE_PATH: vendor/bundle</code>
        </li>
        <li>
            <code>BUNDLE_PATH: /var/alaveteli/bundle</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="new_response_reminder_after_days"><code>NEW_RESPONSE_REMINDER_AFTER_DAYS</code></a>
  </dt>
  <dd>
       Number of days after which to send a 'new response reminder'.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>NEW_RESPONSE_REMINDER_AFTER_DAYS: [3, 10, 24]</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="authority_must_respond"><code>AUTHORITY_MUST_RESPOND</code></a>
  </dt>
  <dd>
    <div class="attention-box info">
      Introduced in Alaveteli version 0.21
    </div>
     Set this to <code>true</code> if authorities must respond by law. Set to <code>false</code> otherwise. It defaults to <code>true</code>. At the moment this just controls the display of some UI text telling users that the authority must respond to them by law.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>AUTHORITY_MUST_RESPOND: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="max_requests_per_user_per_day"><code>MAX_REQUESTS_PER_USER_PER_DAY</code></a>
  </dt>
  <dd>
      This rate limiting can be turned off per-user via the admin interface.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>MAX_REQUESTS_PER_USER_PER_DAY: 6</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="override_all_public_body_request_emails"><code>OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS</code></a>
  </dt>
  <dd>
    If you want to override <strong>all</strong> the public body request emails with
    your own email address so that request emails that would normally go to the public body
    go to you, use this setting.
    This is useful for a staging server, so you can play with the whole process of sending requests
    without inadvertently sending an email to a real authority.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS: test-email@foo.com</code>
        </li>
        <li>
            If you don't want this behaviour, comment the setting out
            <br>
            <code># OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS:</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="public_body_list_fallback_to_default_locale"><code>PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE</code></a>
  </dt>
  <dd>
     If you would like the public body list page to include bodies that have no translation
     in the current locale (but which do have a translation in the default locale), set this to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_widgets"><code>ENABLE_WIDGETS</code></a>
  </dt>
  <dd>
     If you would like to give users the opportunity to insert HTML 'widgets' into their other websites, advertising the
     requests they've made in Alaveteli, set this to true. A link to add a widget will appear in the sidebar of each request page. Users following the link can preview the widget for that request, and cut and paste the HTML to produce the widget into their own site.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_WIDGETS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_two_factor_auth"><code>ENABLE_TWO_FACTOR_AUTH</code></a>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.23.0.0
      </p>
    </div>

    Enable a second step of authentication for dangerous account actions.
    Currently only active for changing password. Two factor auth is opt-in per
    user.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_TWO_FACTOR_AUTH: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_annotations"><code>ENABLE_ANNOTATIONS</code></a>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        Introduced in Alaveteli 0.25.0.0
      </p>
    </div>

    Enable the annotations (comments on requests) feature. Annotations are on
    by default as they've been a standard feature for some time, but this
    setting allows new sites to turn them off if they're not desired.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_ANNOTATIONS: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_public_annotations"><code>ENABLE_PUBLIC_ANNOTATIONS</code></a>
  </dt>
  <dd>
    If set to true, comments (annotations) are allowed on all requests,
    regardless of who made the request. If set to false, comments are only
    allowed by the requester or admin users.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_PUBLIC_ANNOTATIONS: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_user_to_user_messaging"><code>ENABLE_USER_TO_USER_MESSAGING</code></a>
  </dt>
  <dd>
    If set to true, Alaveteli allows users to send messages to each other
    through the site. If set to false, user-to-user messaging is disabled.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_USER_TO_USER_MESSAGING: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="survey_url"><code>SURVEY_URL</code></a>
  </dt>
  <dd>
    If set, one month after a request has been made Alaveteli will email the
    user with a link to a survey at this URL.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>SURVEY_URL: 'https://example.com/survey'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="user_sign_in_activity_retention_days"><code>USER_SIGN_IN_ACTIVITY_RETENTION_DAYS</code></a>
  </dt>
  <dd>
    Retains records of the IP addresses used to sign in to user accounts for the
    configured number of days. This value should be less than or equal to the
    number of days of logs retained by your logrotate configuration, otherwise
    you may hold data in a way that is inconsistent with your privacy policy.
    When set to 0, no sign-in activity is recorded.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>USER_SIGN_IN_ACTIVITY_RETENTION_DAYS: 0</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="blog_feed"><code>BLOG_FEED</code></a>
  </dt>
  <dd>
    <p>These feeds are displayed accordingly on the Alaveteli "blog" page.</p>

    <p>
      Currently WordPress is the only "officially supported" external blog
      feed, but other feeds may work if they use the same data format.
    </p>

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOG_FEED: 'https://www.mysociety.org/category/projects/whatdotheyknow/feed/'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="blog_timeout"><code>BLOG_TIMEOUT</code></a>
  </dt>
  <dd>
    The number of seconds to wait when reading the
    <a href="#blog_feed"><code>BLOG_FEED</code></a> before the request fails.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>BLOG_TIMEOUT: 60</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="facebook_username"><code>FACEBOOK_USERNAME</code></a>
  </dt>
  <dd>
    Makes your Facebook page URL available to the application. Also
    adds a Facebook link to the footer.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>FACEBOOK_USERNAME: whatdotheyknowcom</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="twitter_username"><code>TWITTER_USERNAME</code></a>
    <a name="twitter_widget_id"><code>TWITTER_WIDGET_ID</code></a>
  </dt>
  <dd>
    If you want a twitter feed displayed on the "blog" page, provide the widget ID and username.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>TWITTER_USERNAME: WhatDoTheyKnow</code>
        </li>
        <li>
            <code>TWITTER_WIDGET_ID: '833549204689320031'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="donation_url"><code>DONATION_URL</code></a>
  </dt>
  <dd>
      URL where people can donate to the organisation running the site. If set,
      this will be included in the message people see when their request is
      successful.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>DONATION_URL: "https://www.mysociety.org/donate/"</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="debug_record_memory"><code>DEBUG_RECORD_MEMORY</code></a>
  </dt>
  <dd>
     For debugging memory problems.  If true, Alaveteli logs
     the memory use increase of the Ruby process due to the
     request (Linux only).  Since Ruby never returns memory to the OS, if the
     existing process previously served a larger request, this won't
     show any consumption for the later request.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>DEBUG_RECORD_MEMORY: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="varnish_hosts"><code>VARNISH_HOSTS</code></a>
  </dt>
  <dd>
      If you're running behind Varnish, set this to work out where to send purge
      requests to invalidate the Varnish cache. Otherwise, don't set it. Given as
      a list of hosts.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <pre>
VARNISH_HOSTS:
 - host1
 - host2
</pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="use_mailcatcher_in_development"><code>USE_MAILCATCHER_IN_DEVELOPMENT</code></a>
  </dt>
  <dd>
      <!-- TODO check mailcatcher URL -->
     If true, while in development mode, try to send mail by SMTP to port
     1025 (the port the <a href="http://mailcatcher.me">mailcatcher</a> listens on by default):
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>USE_MAILCATCHER_IN_DEVELOPMENT: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="use_bullet_in_development"><code>USE_BULLET_IN_DEVELOPMENT</code></a>
  </dt>
  <dd>
    Enables <a href="https://github.com/flyerhzm/bullet">Bullet</a>, a tool that
    helps to kill N+1 queries and unnecessary eager loading, while running in
    development mode.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>USE_BULLET_IN_DEVELOPMENT: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="use_ghostscript_compression"><code>USE_GHOSTSCRIPT_COMPRESSION</code></a>
  </dt>
  <dd>
    Currently we default to using pdftk to compress PDFs.  You can
    optionally try Ghostscript, which should do a better job of
    compression.  Some versions of pdftk are buggy with respect to
    compression, in which case Alaveteli doesn't recompress the PDFs at
    all and logs a warning message "Unable to compress PDF" &mdash; which would
    be another reason to try this setting.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>USE_GHOSTSCRIPT_COMPRESSION: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="cache_fragments"><code>CACHE_FRAGMENTS</code></a>
  </dt>
  <dd>
      Use memcached to cache HTML fragments for better performance.
      This will only have an effect in environments where
      <code>config.action_controller.perform_caching</code> is set to true

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>CACHE_FRAGMENTS: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a>
  </dt>
  <dd>
    If set to true, Alaveteli includes extra functionality and account levels
    for professional FOI users, for example journalists. Professional users have
    access to a dashboard, a more streamlined request process, and crucially the
    ability to embargo their requests so that they remain private.
    <p>
      Enabling this is a large change, so you may want to contact the Alaveteli
      team before doing so. See also
      <a href="{{ page.baseurl }}/docs/pro/">Alaveteli Professional</a>.
    </p>
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_ALAVETELI_PRO: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_pro_pricing"><code>ENABLE_PRO_PRICING</code></a>
  </dt>
  <dd>
    If set to true, Alaveteli lets users enter their bank details and subscribe
    to a Stripe subscription which grants them access to the pro role and all the
    features of Alaveteli Professional. This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_PRO_PRICING: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_pro_self_serve"><code>ENABLE_PRO_SELF_SERVE</code></a>
  </dt>
  <dd>
    This option is only used when
    <a href="#enable_pro_pricing"><code>ENABLE_PRO_PRICING</code></a> is set to
    false. If set to true, Alaveteli lets users upgrade their accounts to Pro
    without needing to enter payment details. If set to false, admins receive an
    account request email and have to assign the role in the Alaveteli admin
    interface. This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_PRO_SELF_SERVE: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="enable_projects"><code>ENABLE_PROJECTS</code></a>
  </dt>
  <dd>
    <div class="attention-box">
      <p>
        <strong>Warning:</strong> Projects is not ready for re-use.
      </p>
    </div>
    Enables the Projects feature. This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ENABLE_PROJECTS: false</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_contact_email"><code>PRO_CONTACT_EMAIL</code></a>
  </dt>
  <dd>
    Contact email address for Alaveteli Professional. Requests made through
    Alaveteli Professional may be embargoed, meaning the user expects them to be
    private, which can include being private from some of the site's
    administration team. Even where this is not the case, you may wish to
    redirect pro support email away from the usual address. If you want all
    support mail to go to the same address, make this the same as
    <a href="#contact_email"><code>CONTACT_EMAIL</code></a>. This only takes
    effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PRO_CONTACT_EMAIL: 'pro-contact@localhost'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_contact_name"><code>PRO_CONTACT_NAME</code></a>
  </dt>
  <dd>
    The name to address emails to when sending email to
    <a href="#pro_contact_email"><code>PRO_CONTACT_EMAIL</code></a>. If you want
    all support mail to go to the same address, make this the same as
    <a href="#contact_name"><code>CONTACT_NAME</code></a>. This only takes effect
    when <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PRO_CONTACT_NAME: 'Alaveteli Professional'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_site_name"><code>PRO_SITE_NAME</code></a>
  </dt>
  <dd>
    The name to use when referring to the Alaveteli Professional parts of an
    Alaveteli site. For example, in the UK the mySociety instance is called
    "WhatDoTheyKnow" but the pro parts of the site are referred to as
    "WhatDoTheyKnow Pro". If you don't want a different name for the pro pages,
    make this the same as <a href="#site_name"><code>SITE_NAME</code></a>. This
    only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PRO_SITE_NAME: 'Alaveteli Professional'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_batch_authority_limit"><code>PRO_BATCH_AUTHORITY_LIMIT</code></a>
  </dt>
  <dd>
    The total number of authorities that can be added to an Alaveteli
    Professional batch request. This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PRO_BATCH_AUTHORITY_LIMIT: 500</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="pro_referral_coupon"><code>PRO_REFERRAL_COUPON</code></a>
  </dt>
  <dd>
    A Stripe coupon code, displayed to existing Pro users on their subscriptions
    page, that they can share with friends so those friends receive a signup
    discount. This should not include the
    <a href="#stripe_namespace"><code>STRIPE_NAMESPACE</code></a>. You must set a
    <code>humanized_terms</code> key in the coupon metadata to display the
    discount that will be applied when using the coupon (for example, "50% off
    for 1 month"). This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>PRO_REFERRAL_COUPON: 'PROREFERRAL'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="external_reviewers"><code>EXTERNAL_REVIEWERS</code></a>
  </dt>
  <dd>
    Enable referral of requests to external reviewers. This is likely to be an
    Information Commissioner or similar. This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>EXTERNAL_REVIEWERS: ico@example.net</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="forward_pro_nonbounce_responses_to"><code>FORWARD_PRO_NONBOUNCE_RESPONSES_TO</code></a>
  </dt>
  <dd>
    The email address to which non-bounce responses to emails sent out to
    Alaveteli Professional users should be forwarded. This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>FORWARD_PRO_NONBOUNCE_RESPONSES_TO: pro-user-support@example.com</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_publishable_key"><code>STRIPE_PUBLISHABLE_KEY</code></a>
  </dt>
  <dd>
    <a href="https://stripe.com">Stripe.com</a> publishable key. This only takes
    effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>STRIPE_PUBLISHABLE_KEY: pk_test_UD6BDsARFZIYb8273dbdl</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_secret_key"><code>STRIPE_SECRET_KEY</code></a>
  </dt>
  <dd>
    <a href="https://stripe.com">Stripe.com</a> secret key. This only takes
    effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>STRIPE_SECRET_KEY: sk_test_UD6BDsARFZIYb8273dbdl</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_namespace"><code>STRIPE_NAMESPACE</code></a>
  </dt>
  <dd>
    An optional Stripe.com namespace which allows plans and coupons to be
    separated from other resources within Stripe. If used, the Stripe resources
    need IDs like <code>&lt;namespace&gt;-&lt;id&gt;</code>. Must be uppercase.
    This only takes effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>STRIPE_NAMESPACE: 'ALAVETELI'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_prices"><code>STRIPE_PRICES</code></a>
  </dt>
  <dd>
    A list of Stripe Prices which, if a user signs up to, grant them access to
    Alaveteli Pro. These are rendered on the pro pricing pages in the order
    defined here. Given as a hash whose keys are the Stripe Price IDs and whose
    values are a parameterised, short, human-readable string. Historical Stripe
    Price IDs listed here should include the
    <a href="#stripe_namespace"><code>STRIPE_NAMESPACE</code></a>. This only takes
    effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <pre>
STRIPE_PRICES:
  pro: pro
</pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_webhook_secret"><code>STRIPE_WEBHOOK_SECRET</code></a>
  </dt>
  <dd>
    <a href="https://stripe.com">Stripe.com</a> webhook secret. This only takes
    effect when
    <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>STRIPE_WEBHOOK_SECRET: wh_test_UD6BDsARFZIYb8273dbdl</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="stripe_tax_rate"><code>STRIPE_TAX_RATE</code></a>
  </dt>
  <dd>
    The rate of tax / VAT to add to Pro subscriptions. Note that the price per
    unit of your Stripe product plan must be created without tax; Alaveteli
    automatically calculates the gross amount to charge. This only takes effect
    when <a href="#enable_alaveteli_pro"><code>ENABLE_ALAVETELI_PRO</code></a> is set to true.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>STRIPE_TAX_RATE: '0.20'</code>
        </li>
      </ul>
    </div>
  </dd>

</dl>

<a name="other-config"> </a>

## Other configuration settings and files

There are more configuration settings for [Alaveteli Professional](
  {{ page.baseurl }}/docs/pro/
) and [Alaveteli Pro Pricing](
  {{ page.baseurl }}/docs/pro/pricing/
).

Note that there are other configuration files for Alaveteli &mdash; you'll find them all
in the `config` directory. These are presented in the git repository as `*-example` files
which you can copy into place.

<dl>
  <dt>
    <strong>database.yml</strong>
  </dt>
  <dd>
    database settings (as per Rails)
  </dd>
  <dt>
    <strong>deploy.yml</strong>
  </dt>
  <dd>
    deployment specifications used by Capistrano
  </dd>
  <dt>
    <strong>httpd.conf, nginx.conf</strong>
  </dt>
  <dd>
    Apache and Nginx configuration suggestions
  </dd>
  <dt>
    <strong>user_spam_scorer.yml</strong>
  </dt>
  <dd>
    optional per-site tuning of the user spam scorer, which scores new user
    accounts for spam signals. You can adjust the weight given to each check
    via <code>score_mappings</code> &mdash; including the three
    <a href="https://www.usercheck.com">UserCheck.com</a> email-domain checks
    enabled by
    <code><a href="#usercheck_api_key">USERCHECK_API_KEY</a></code> &mdash;
    and override the lists of suspicious and spam email domains. Copy
    <code>config/user_spam_scorer.yml-example</code> into place to use it
  </dd>
</dl>
