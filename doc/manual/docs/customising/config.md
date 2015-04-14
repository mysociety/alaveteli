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

The alaveteli code ships with an example configuration file: `config/general.yml-example`.

As part of the [installation process]({{ page.baseurl }}/docs/installing/ ), the
example file gets copied to `config/general.yml`. You **must** edit this file to
suit your needs.

Note that the default settings for frontpage examples are designed to work with
the dummy data shipped with Alaveteli. Once you have real data, you should
certainly edit these.

Note that there are [other configuration files](#other-config) too, for specific aspects of Alaveteli.


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
<br> <code><a href="#theme_branch">THEME_BRANCH</a></code>
<br> <code><a href="#frontpage_publicbody_examples">FRONTPAGE_PUBLICBODY_EXAMPLES</a></code>
<br> <code><a href="#public_body_statistics_page">PUBLIC_BODY_STATISTICS_PAGE</a></code>
<br> <code><a href="#minimum_requests_for_statistics">MINIMUM_REQUESTS_FOR_STATISTICS</a></code>
<br> <code><a href="#responsive_styling">RESPONSIVE_STYLING</a></code>

### Site status:

<code><a href="#read_only">READ_ONLY</a></code>
<br> <code><a href="#staging_site">STAGING_SITE</a></code>

### Locale and internationalisation:

<code><a href="#iso_country_code">ISO_COUNTRY_CODE</a></code>
<br> <code><a href="#time_zone">TIME_ZONE</a></code>
<br> <code><a href="#available_locales">AVAILABLE_LOCALES</a></code>
<br> <code><a href="#default_locale">DEFAULT_LOCALE</a></code>
<br> <code><a href="#use_default_browser_language">USE_DEFAULT_BROWSER_LANGUAGE</a></code>
<br> <code><a href="#include_default_locale_in_urls">INCLUDE_DEFAULT_LOCALE_IN_URLS</a></code>

### Definition of "late":

<code><a href="#reply_late_after_days">REPLY_LATE_AFTER_DAYS</a></code>
<br> <code><a href="#reply_very_late_after_days">REPLY_VERY_LATE_AFTER_DAYS</a></code>
<br> <code><a href="#special_reply_very_late_after_days">SPECIAL_REPLY_VERY_LATE_AFTER_DAYS</a></code>
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

### General admin (keys, paths, back-end services):

<code><a href="#cookie_store_session_secret">COOKIE_STORE_SESSION_SECRET</a></code>
<br> <code><a href="#recaptcha_public_key">RECAPTCHA_PUBLIC_KEY</a></code>
<br> <code><a href="#recaptcha_private_key">RECAPTCHA_PRIVATE_KEY</a></code>
<br> <code><a href="#gaze_url">GAZE_URL</a></code>
<br> <code><a href="#ga_code">GA_CODE</a></code> (GA=Google Analytics)
<br> <code><a href="#utility_search_path">UTILITY_SEARCH_PATH</a></code>
<br> <code><a href="#shared_files_path">SHARED_FILES_PATH</a></code>
<br> <code><a href="#shared_files">SHARED_FILES</a></code>
<br> <code><a href="#shared_directories">SHARED_DIRECTORIES</a></code>

### Behaviour settings and switches:

<code><a href="#new_response_reminder_after_days">NEW_RESPONSE_REMINDER_AFTER_DAYS</a></code>
<br> <code><a href="#authority_must_respond">AUTHORITY_MUST_RESPOND</a></code>
<br> <code><a href="#max_requests_per_user_per_day">MAX_REQUESTS_PER_USER_PER_DAY</a></code>
<br> <code><a href="#override_all_public_body_request_emails">OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS</a></code>
<br> <code><a href="#allow_batch_requests">ALLOW_BATCH_REQUESTS</a></code>
<br> <code><a href="#public_body_list_fallback_to_default_locale">PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE</a></code>

### External public services:

<code><a href="#blog_feed">BLOG_FEED</a></code>
<br> <code><a href="#twitter_username">TWITTER_USERNAME</a></code>
<br> <code><a href="#twitter_widget_id">TWITTER_WIDGET_ID</a></code>
<br> <code><a href="#donation_url">DONATION_URL</a></code>

### Development work or special cases:

<code><a href="#debug_record_memory">DEBUG_RECORD_MEMORY</a></code>
<br> <code><a href="#varnish_host">VARNISH_HOST</a></code>
<br> <code><a href="#use_mailcatcher_in_development">USE_MAILCATCHER_IN_DEVELOPMENT</a></code>
<br> <code><a href="#use_ghostscript_compression">USE_GHOSTSCRIPT_COMPRESSION</a></code>
<br> <code><a href="#html_to_pdf_command">HTML_TO_PDF_COMMAND</a></code>
<br> <code><a href="#cache_fragments">CACHE_FRAGMENTS</a></code>


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
    Does a user needs to sign in to start the New Request process?
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
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
 - 'git://github.com/mysociety/alavetelitheme.git'
</pre>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="theme_branch"><code>THEME_BRANCH</code></a>
  </dt>
  <dd>
    When <code>rails-post-deploy</code> installs the <a href="{{ page.baseurl }}/docs/customising/themes/">themes</a>,
    it will try the theme branch first, but only if you've set <code>THEME_BRANCH</code>
    to be true. If the branch doesn't exist it will fall back to using a tagged version
    specific to your installed alaveteli version, and if that doesn't exist it will
    back to <code>master</code>.
    <p>
        The default theme is the "Alaveteli" theme. This gets installed automatically when
        <code>rails-post-deploy</code> runs.
    </p>
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
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
            <code>MINIMUM_REQUESTS_FOR_STATISTICS: 50</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="responsive_styling"><code>RESPONSIVE_STYLING</code></a>
  </dt>
  <dd>

     Use the responsive base stylesheets and templates, rather than
     those that only render the site at a fixed width. These
     stylesheets are currently experimental but will become the default
     in the future. They allow the site to render nicely on mobile
     devices as well as larger screens. Currently the fixed width
     stylesheets are used by default.

    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>RESPONSIVE_STYLING: true</code>
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
    <a name="include_default_locale_in_urls"><code>INCLUDE_DEFAULT_LOCALE_IN_URLS</code></a>
  </dt>
  <dd>
    Normally, Alaveteli will put the locale into its URLs, like this
    <code>www.example.com/en/body/list/all</code>. If you don't want this
    behaviour whenever the locale is the default one, set
    <strong>INCLUDE_DEFAULT_LOCALE_IN_URLS</strong> to false.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>INCLUDE_DEFAULT_LOCALE_IN_URLS: true</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="reply_late_after_days"><code>REPLY_LATE_AFTER_DAYS</code></a><br>
    <a name="reply_very_late_after_days"><code>REPLY_VERY_LATE_AFTER_DAYS</code></a><br>
    <a name="special_reply_very_late_after_days"><code>SPECIAL_REPLY_VERY_LATE_AFTER_DAYS</code></a>
    <a name="working_or_calendar_days"><code>WORKING_OR_CALENDAR_DAYS</code></a>
  </dt>
  <dd>
        The <strong>REPLY...AFTER_DAYS</strong> settings define how many days must have
        passed before an answer to a request is officially <em>late</em>.
        The SPECIAL case is for some types of authority (for example: in the UK, schools) which are
        granted a bit longer than everyone else to respond to questions.
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
            <code>SPECIAL_REPLY_VERY_LATE_AFTER_DAYS: 60</code>
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
        <a href="{{ page.baseurl }}/docs/installing/next_steps/#create-a-superuser-admin-account">creating
          a superuser account</a>.
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
      Are you using "exim" or "postfix" for your Mail Transfer Agnt (MTA)?

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
    <a name="cookie_store_session_secret"><code>COOKIE_STORE_SESSION_SECRET</code></a>
  </dt>
  <dd>
     Secret key for signing cookie_store sessions. Make it long and random.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>COOKIE_STORE_SESSION_SECRET: 'uIngVC238Jn9NsaQizMNf89pliYmDBFugPjHS2JJmzOp8'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
      <a name="recaptcha_public_key"><code>RECAPTCHA_PUBLIC_KEY</code></a> &amp;
      <a name="recaptcha_private_key"><code>RECAPTCHA_PRIVATE_KEY</code></a>
  </dt>
  <dd>
     Recaptcha, for detecting humans. Get keys here:
     <a href="http://recaptcha.net/whyrecaptcha.html">http://recaptcha.net/whyrecaptcha.html</a>

    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>RECAPTCHA_PUBLIC_KEY: '7HoPjGBBBBBBBBBkmj78HF9PjjaisQ893'</code>
        </li>
        <li>
            <code>RECAPTCHA_PRIVATE_KEY: '7HjPjGBBBBBCBBBpuTy8a33sgnGG7A'</code>
        </li>
      </ul>
    </div>
  </dd>

  <dt>
    <a name="gaze_url"><code>GAZE_URL</code></a>
  </dt>
  <dd>
      Alateveli uses mySociety's gazeteer service to determine country from incoming
      IP address (this lets us suggest an Alaveteli in their country, if one exists).
      You shouldn't normally need to change this.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>GAZE_URL: http://gaze.mysociety.org</code>
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
      Search path for external command-line utilities (such as pdftohtml, pdftk, unrtf).
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
 - config/rails_env.rb
 - config/newrelic.yml
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
 - vendor/bundle
 - public/assets
            </pre>
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
    <a name="allow_batch_requests"><code>ALLOW_BATCH_REQUESTS</code></a>
  </dt>
  <dd>
     Allow some users to make batch requests to multiple authorities. Once
     this is set to true, you can enable batch requests for an individual
     user via the user admin page.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>ALLOW_BATCH_REQUESTS: false</code>
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
    <a name="blog_feed"><code>BLOG_FEED</code></a>
  </dt>
  <dd>
    These feeds are displayed accordingly on the Alaveteli "blog" page: <!-- TODO -->
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
    <a name="varnish_host"><code>VARNISH_HOST</code></a>
  </dt>
  <dd>
      If you're running behind Varnish, it might help to set this to
      work out where to send purge requests.
      Otherwise, don't set it.
    <div class="more-info">
      <p>Examples:</p>
      <ul class="examples">
        <li>
            <code>VARNISH_HOST: null</code>
        </li>
        <li>
            <code>VARNISH_HOST: localhost</code>
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
    <a name="html_to_pdf_command"><code>HTML_TO_PDF_COMMAND</code></a>
  </dt>
  <dd>
    Path to a program that converts an HTML page in a file to PDF.  It
    should take two arguments: the URL, and a path to an output file.
    A static binary of <a href="http://wkhtmltopdf.org">wkhtmltopdf</a> is recommended.
    If the command is not present, a text-only version will be rendered
    instead.
    <div class="more-info">
      <p>Example:</p>
      <ul class="examples">
        <li>
            <code>HTML_TO_PDF_COMMAND: /usr/local/bin/wkhtmltopdf-amd64</code>
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

</dl>

<a name="other-config"> </a>

## Other configuration files

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
    <strong>newrelic.yml</strong>
  </dt>
  <dd>
    Analytics configuration
  </dd>
</dl>
