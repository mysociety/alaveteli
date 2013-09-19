# Version 0.14

## Highlighted features
* There is now an option to display a public body statistics page (currently not linked to from anywhere) showing bodies with the most requests, most successful requests, fewest successful requests, most overdue requests, and bodies that reply most frequently with "Not Held" - see Upgrade notes for how to turn this option on. (Mark Longair)
* Individual incoming and outgoing messages can be made hidden, or requester_only from the admin interface.
* Zip downloads now can be run in single-threaded instances, and use send_file rather than a redirect to serve up cached zip files.
* Starting to use factory_girl to generate model instances for use in specs - hopefully in the long term removing dependencies between specs, and allowing them to run faster once we can remove the loading of fixtures each time.
* Fix to allow public body list page to use current, not default locale, with optional fallback to default [issue #1000](https://github.com/mysociety/alaveteli/issues/1000) - see Upgrade notes for fallback option (Mark Longair)
* Fix to allow request titles composed of only unicode characters [issue #902](https://github.com/mysociety/alaveteli/issues/902)
* Fix for occasional errors caused by race conditions in xapian updates [issue #555](https://github.com/mysociety/alaveteli/issues/555)
* Diagnostic errors are now not shown for local requests, so that the user-facing error pages will be shown when running Alaveteli behind a proxy in production (Henare Degan)

## Upgrade notes
* By default, Alaveteli will now serve up request zip files itself, which will occupy a Rails process until the file has been received. To pass these files off to Apache, and free up the Rails process, install the libapache2-mod-xsendfile package, and update your httpd.conf file with the new Sendfile clause at the end of config/httpd.conf-example).
* In your production install, from the Alaveteli directory (as the Alaveteli deploy user), run the following commands to remove the zip download directory from direct access by your webserver, and preserve any cached zip files:
`mkdir cache/zips/production/`
`mv cache/zips/download cache/zips/production/download`
`rm public/download`
* This release upgrades the assumed version of Ubuntu from lucid (10.04) to precise (12.04)
* This release upgrades rubygems in config/packages - version 1.8.15 is available from squeeze-backports on Debian or by default in Ubuntu precise. This upgrade may result in "invalid date format in specification:" errors - these should be fixable by manually deleting the gems specs that are being referenced in the error and re-running rails-post-deploy
* If you would like to have a public body statistics page (this will be publicly available), set the `PUBLIC_BODY_STATISTICS_PAGE` param in general.yml to `true`. You should also add a new cron job based on the one in config/crontab-example `https://github.com/mysociety/alaveteli/blob/rails-3-develop/config/crontab-example#L29` to update the public body stats each day.
* If you would like the public body list page to include bodies that have no translation in the current locale, but do have a translation in the default locale, add a `PUBLIC_BODY_LIST_FALLBACK_TO_DEFAULT_LOCALE` param set to `true` to your config/general.yml file.


# Version 0.13
## Highlighted features

* Fix for bug that resulted in some incorrect results when using search by request status [issue #460](https://github.com/mysociety/alaveteli/issues/460). You can view and fix requests with inconsistent state history using `rake temp:fix_bad_request_states`
* All status updates (whether by the request owner or another user) are now logged in the event history, for better audit) (Matthew Landauer)
* Fix for bug that dropped accented characters from URLs [issue #282](https://github.com/mysociety/alaveteli/issues/282) (zejn)
* A fix for a bug that produced binary mask errors when handling multibyte characters in responses [issue #991](https://github.com/mysociety/alaveteli/issues/991)
* Some locale fixes for locales with a dash in them [issue #998](https://github.com/mysociety/alaveteli/issues/998) and [issue #999](https://github.com/mysociety/alaveteli/issues/999).
* Some improvements in the labelling of defunct authorities (Matthew Somerville)
* The addition of a check on the status of the commonlib submodule to the rails-post-deploy script.

## Upgrade notes
* Check out this version and run `rails-post-deploy` as usual.
* This release includes an update to the commonlib submodule - you should now be warned about this on running `rails-post-deploy`. You can update to the new version with `git submodule update`.
* After deploying, run `rake temp:fix_bad_request_states` to find and list requests that have an inconsistent history - run `rake temp:fix_bad_request_states DRYRUN=0` to fix them.

# Version 0.12
## Highlighted features
*  Remove support for theme stylesheet inclusion via template (deprecated in version 0.5)
* Addition of a simple JSON API for querying the Ruby and Alaveteli version of an Alaveteli instance - made available at /version.json (Matthew Landauer)
* Users can now give more information when reporting a request as unsuitable (Matthew Landauer)
* The donation url presented to users when they report their request as successful or partially successful is now option and the url itself can be configured using the config param DONATION_URL
* Internal review request text is now translatable
* config/crontab.ugly is now config/crontab-example
* Search query highlighting should now work with non-ascii characters [issue #505](https://github.com/mysociety/alaveteli/issues/505) (Matthew Landauer)
* A bug that allowed people to sign up with email addresses with spaces in them has been fixed [issue #980](https://github.com/mysociety/alaveteli/issues/980). Any existing email addresses with spaces in them will cause problems e.g. when the cron scripts encounter them. You can fix them manually, or by running `rake temp:clean_up_emails_with_spaces` from `lib/tasks/temp.rake`
* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=30&state=closed)

## Upgrade notes
* Check out this version and run `rails-post-deploy` as usual.
* Add a DONATION_URL to your config/general.yml file if you want to use your own donation URL.

# Version 0.11
## Highlighted features
* Upgrade of the Rails framework to version 3.1.12 (Henare Degan, Matthew Landauer, Mark Longair, Louise Crow)

## Upgrade notes
* Manually remove vendor/rails-locales
* Themes created for 0.9 and below should be updated to work with Rails 3. See `THEMES-UPGRADE.md` for notes on upgrading your theme. You will need to manually remove your old theme directory before running `rails-post-deploy`.
* The `config/httpd.conf` has moved to `config/httpd.conf-example`, as it may need customization before deploying. It also has a new line setting RackEnv to production - copy this to your config/httpd.conf file.
* Alaveteli now uses the [mail gem](https://github.com/mikel/mail) rather than [tmail](https://github.com/mikel/tmail) to handle mail. If you're using Exim as your MTA, you'll need to use the setting `extract_addresses_remove_arguments = false` in your Exim conf (see INSTALL-exim4.md for details). This means it won't remove addresses specified with -t on command line from the mail recipient list.

# Version 0.9
## Highlighted features
* Consistent and more informative variable interpolation syntax in translated phrases. All of these phrases will now appear in the form "There are {{count}} people following this request", where some were previously in the form "There are %s people following this request". (Matthew Landauer)
* Replaces deprecated calls to with_locale on ActiveRecord classes in preparation for upgrade to Globalize3 (Matthew Landauer)
* Fixes a database deadlock bug caused by near-simultaneous incoming emails for the same info request (Mark Longair)

## Upgrade notes
* Check out this version and run `rails-post-deploy` as usual.


# Version 0.8
## Highlighted features
* Support for running the site over SSL/TLS only and corresponding removal of support for a proxied admin interface, including the deprecation of the main_url and admin_url helpers.
* Merging of the adminbootstrap theme into core Alaveteli, replacing the existing admin theme. (Matthew Landauer)
* Move to HTML 5 (Matthew Landauer)
* More consistent UI for links in the admin interface
* [Security] Upgrades the Rails version to 2.3.17 to get fixes for CVE-2013-0277, CVE-2013-0276 (Although core Alaveteli does not use serialize or attr_protected), upgrade JSON gem to get fix for CVE-2013-0269.
* A bugfix for Chrome's autofilling of signup fields (Vaughan Rouesnel)
* Improvements to the accessibility of the search boxes (Nathan Jenkins)
* Only one email sent when asking for admin attention to a request  [issue #789](https://github.com/mysociety/alaveteli/pull/864) (Matthew Landauer)
* A number of XSS escaping fixes for Version 0.7 (Matthew Landauer)
* The emergency admin account can now be disabled

## Upgrade notes
* Check out this version and run `rails-post-deploy` as usual.
* Remove adminbootstrap from the THEME_URLS or THEME_URL config variable, and remove vendor/plugins/adminbootstraptheme, and the softlink public/adminbootstraptheme.
* There is a new config variable FORCE_SSL, which defaults to true, meaning that Alaveteli will redirect all "http" requests to "https", set the Strict-Transport-Security header and flag all cookies as "secure". For more information about running your install over SSL/TLS, see the [install guide](https://github.com/mysociety/alaveteli/blob/develop/doc/INSTALL.md#set-up-production-web-server). If you don't want to run over SSL/TLS, add the config variable FORCE_SSL to your config/general.yml and set it to false.
* If you would like to disable the emergency user account, set DISABLE_EMERGENCY_USER to true in you config/general.yml

# Version 0.7
## Highlighted features
* [Security] Upgrades the Rails version from 2.3.15 to 2.3.16 to get fix for a critical security flaw in Rails (CVE-2013-0333).
* Adds rails_xss gem to make HTML escaping the default behaviour in views.
* Allows cap rake:themes:install to be run standalone and in the context of a deploy.
* Gem bundle is always installed in the vendor directory, even in development mode.
* Interlock plugin removed.
* Models have named validation methods, and don't overwrite validate anymore.

## Upgrade notes
* Check out this version and run `rails-post-deploy` as usual.
* Check your themes for any strings that are now being escaped but shouldn't be and either use raw or .html_safe to resolve them. Don't do this with strings from user input!

# Version 0.6.9
## Highlighted features
* [Security] Fix for security issue where image files from HTML conversion on hidden/requester-only requests were accessible without authentication [issue #739](https://github.com/mysociety/alaveteli/issues/739).
* [Security] Fix for issue where the zip file download function was available for logged-in users even on hidden/requester-only requests [issue #743](https://github.com/mysociety/alaveteli/issues/743)
* [Security] Upgrades to Rails 2.3.15 to get fixes for Rails security flaws CVE-2012-5664 and CVE-2013-0156. In addition, switches to use Rails pulled from a clone in the mySociety github account, which has had the CVE-2013-0155 2.3 series patch applied to it.
* Isolation of mail handling code in the MailHandler module in lib/mail_handler
* Tests run under Ruby 1.9.3 - *running the app under 1.9 not yet advised*.
* Routes without a locale part can be enabled for the default locale - see upgrade notes
* Fixes to support themed error pages, and allow responsive themes (Matthew Landauer, Brendan Molloy)
* Migrations run under sqlite (Stefan Langenmaier)
* Time zone fixes (Henare Degan)
* Faster tests (Henare Degan)

* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=25&state=closed)

## Upgrade notes
* Note the new config variable INCLUDE_DEFAULT_LOCALE_IN_URLS (if not set defaults to true, which should replicate existing behaviour)
* Check out this version and run `rails-post-deploy` as usual.

# Version 0.6.8
## Highlighted features

* Support for using Postfix as Alaveteli's MTA, instead of Exim (Matthew Landauer)
* Some preparation for getting Alaveteli working with Ruby 1.9 (James McKinney) - more to come here in future releases!
* Optional support for using New Relic for performance monitoring (Matthew Landauer)
* Support for showing all dates and times in the local time zone (Matthew Landauer)
* Display of authority disclosure logs where the URL is added (Matthew Landauer)
* Better handling of nil/empty option config parameters (Henare Degan)
* The option to specify a particular theme branch to use (Matthew Landauer)
* Some performance improvements, particularly over 0.6.7 (Louise Crow)

* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=24&state=closed)

## Upgrade notes
* Ensure you have values for new config variables (see `config/general.yml-example`):
  * TIME_ZONE (if not set, defaults to UTC)
  * TWITTER_WIDGET_ID (no Twitter widget is displayed if not set)
  * THEME_BRANCH (defaults to tagged version specific to your version of alaveteli or, failing that, to master)
  * MTA_LOG_PATH
  * MTA_LOG_TYPE (defaults to Exim)
* IMPORTANT - Copy config/newrelic.yml-example to config/newrelic.yml - by default monitoring is switched off, see https://github.com/newrelic/rpm for instructions on switching on local and remote performance analysis.
* Check out this version and run `rails-post-deploy` as usual.
* Note that mailcatcher is now used in development - see http://mailcatcher.me/ for details

# Version 0.6.7
## Highlighted features
* The ability to calculate due dates using calendar, not working days (Matthew Landauer)
* A refactor and standardization of the configuation variables and defaults using a central module (Matthew Landauer)
* The use of full URLs in admin attention emails, and associated modification of the admin_url helper to always return full urls (Henare Degan)
* The ability to disable comments on a request (Robin Houston)
* Some previously missed strings for translation, courtesy of the Czech translation team

* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=23&state=closed)


## Upgrade notes

* Themes created for 0.6.6 and below should be updated to use the new Configuration module wherever they used Config.get directly previously.
* Check out this version and run `rails-post-deploy` as usual.


# Version 0.6.6
## Highlighted features
* Adds deployment via Capistrano - see DEPLOY.md for details
* Speeds up several admin pages that were slow in large installs

* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=22&state=closed)

## Upgrade notes

* Check out this version and run `rails-post-deploy` as usual.
* Run `rake temp:populate_request_classifications` to populate the new request_classifications table which is used in generating the request categorisation game league tables and progress widget.

# Version 0.6.5
* This is a minor release, to update all documentation and example files to reflect the move of the official repository to http://github.com/mysociety/alaveteli and the alavetelitheme and adminbootstraptheme themes to http://github.com/mysociety/alavetelitheme and http://github.com/mysociety/adminbootstraptheme respectively.
* Some basic versioning has been added for themes. An ALAVETELI_VERSION constant has been added in config/environment.rb. When loading themes, `rails-post-deploy` now looks for a tag on the theme repository in the form 'use-with-alaveteli-0.6.5' that matches the ALAVETELI_VERSION being deployed - if it finds such a tag, the theme will be checked out from that tag, rather than from the HEAD of the theme repository. If no such tag is found, HEAD is used, as before [issue #573](https://github.com/mysociety/alaveteli/issues/573).
* Apache has been configured to serve cached HTML versions of attached files (and associated images) directly from the file cache, as well as the original versions [issue #580](https://github.com/mysociety/alaveteli/issues/580).
* PublicBodyCategories have a couple of new methods for more easily working with headings [issue #575](https://github.com/mysociety/alaveteli/issues/575).

* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=21&state=closed)

## Upgrade notes

* Please update your `THEME_URLS` to point to http://github.com/mysociety/alavetelitheme and http://github.com/mysociety/adminbootstraptheme if you are using the alavetelitheme or adminbootstraptheme themes.

* Check out this version and run `rails-post-deploy` as usual.

# Version 0.6.4
## Highlighted features
* This is a minor bugfix release, mainly to fix bugs related to external request handling.
* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=18&state=closed)
* [List of commits since last release](https://github.com/mysociety/alaveteli/compare/master...release/0.6.4)

## Upgrade notes

* No special action required -- just check out this version and run
  `rails-post-deploy` as usual.

# Version 0.6.3
## Highlighted features
* This is a minor release, mainly to publish new customisation
  features required by the upcoming
  [Czech Republic theme](https://github.com/pepe/ipvtheme)
* Administrators can now use regular expressions when making Censor Rules
* It is also now possible to create "global" Censor Rules that apply
  to all content types in the site; however, this power is not exposed
  to UI users.
* Some new i18n fixes and template refactoring to allow more extensive
  customisation in themes
* Themes can now provide a `post_install.rb` script that is executed
  by `rails-post-deploy`
* [List of issues on github](https://github.com/mysociety/alaveteli/issues?milestone=17&state=closed)

## Upgrade notes

* No special action required -- just check out this version and run
  `rails-post-deploy` as usual.

# Version 0.6.2
## Highlighted features

* This is a minor release to fix small bugs in documentation and install/upgrade process
* It also includes support for [Continuous Integration using Travis](http://travis-ci.org/)

## Upgrade notes

* No special action required -- just check out this version and run
  `rails-post-deploy` as usual.

# Version 0.6.1
## Highlighted features

* Fixes important security bug [issue #515](https://github.com/mysociety/alaveteli/issues/515)
* Show admin nav bar when browsing main site
* A new API for adding requests and correspondence to an Alaveteli
  instance, designed for use by public bodies that wish to use
  Alaveteli as a disclosure log.  See
  [the wiki](https://github.com/mysociety/alaveteli/wiki/API) for some
  documentation.
* [Full list of changes on github](https://github.com/mysociety/alaveteli/issues?milestone=8&state=closed)

## Upgrade notes

* No special action required -- just check out this version and run
  `rails-post-deploy` as usual.

# Version 0.6

## Highlighted features

* Ruby dependencies are now handled by Bundler
* Support for invalidating accelerator cache -- this makes it much
  less likely, when using Varnish, that users will be presented with
  stale content.  Fixes

* Adding a `GA_CODE` to `general.yml` will cause the relevant Google
  Analytics code to be added to your rendered pages
* It is now possible to have more than one theme installed.  The
  behaviour of multiple themes is now layered in the reverse order
  they're listed in the config file.  See the variable `THEME_URLS` in
  `general.yml-example` for an example.
* A new, experimental theme for the administrative interface.  It's
  currently packaged as a standalone theme, but will be merged into
  the core once it's been tested and iterated in production a few
  times.  Thanks to @wombleton for kicking this off!
* Alert subscriptions are now referred to as "following" a request (or
  group of requests) throughout the UI.  When a user "follows" a
  request, updates regarding that request are posted on a new "wall"
  page.  Now they have a wall, users can opt not to receive alerts by
  email.
* New features to support fast post-moderation of bad requests: a
  button for users to report potentially unsuitable requests, and a
  form control in the administrative interface that hides a request
  and sends the user an email explaining why.
* A bug which prevented locales containing underscores (e.g. `en_GB`)
  was fixed
  ([issue #503](https://github.com/mysociety/alaveteli/issues/503))
* Error pages are now presented with styling from themes
* [Full list of changes on github](https://github.com/mysociety/alaveteli/issues?milestone=13&state=closed)

## Upgrade notes

* As a result of using bundler, the list of software packages that
  should be installed has changed.  On Debian, you can run:

      sudo apt-get install `cut -d " " -f 1 config/packages | grep -v "^#"`

  [This gist](https://gist.github.com/2584766) shows the changes to
  `config/packages` since the previous release.

* Existing installations will need to install Bundler.  On Debian this
  is done by the above command.  See `INSTALL.md` for details.

* Because dependencies are now handled by Bundler, when you next run
  the `rails-post-deploy` script, it will download, compile and
  install various things.  Part of this is compiling xapian, which will
  take a *long* time (subsequent deployments will be much faster)

* To support invalidating the Varnish cache, ensure that there's a
  value for `VARNISH_HOST` in `general.yml` (normally this would be
  `localhost`).  You will also need to update your Varnish server to
  support PURGE requests.  The example configuration provided at
  `config/varnish-alaveteli.vcl` will work for Varnish 3 and above. If
  you leave `VARNISH_HOST` blank, it will have no effect.  Finally,
  you should install the `purge-varnish` init script that's provided
  in `ugly` format at `config/purge-varnish-debian.ugly` to ensure the
  purge queue is emptied regularly.  Once deployed, you should also
  check your production log for lines starting `PURGE:` to ensure the
  purges are successful (a failure will typically be due to a
  misconfigured Varnish).  If purges are unsuccessful, the conseqence
  is that individual request pages that are served to anonymous users
  will be up to 24 hours out of date.

* Administrators are now assumed to log in using standard user accounts
  with superuser privileges (see 'Administrator Privileges' in
  `INSTALL.md`). The old-style admin account (using credentials from
  `general.yml`) is now known as the "emergency user".  Deployments
  that previously bypassed admin authentication should set the new
  `SKIP_ADMIN_AUTH` config variable to `true`.

* If you want to try out the new administrator theme, copy the sample
  `THEME_URLS` config from `general.yml-example` and run
  `./script/rails-post-deploy`.  If you don't like it, turn it off
  again by removing the line referring to the theme
  (`adminbootstraptheme`) -- but email the mailing list first,
  explaining why!  The intention is to merge this theme into the
  Alaveteli core in a future release.

* If you are already using Google Analytics, you are probably
  including the tracking code manually in your theme.  If you'd like
  to use Alaveteli's support for Google Analytics, set the `GA_CODE`
  in `general.yml` and remove all reference to the tracking code from
  your theme.

* Here's a list of all the new config variables you might want to change:
  * `THEME_URLS`
  * `SKIP_ADMIN_AUTH`
  * `VARNISH_HOST`
  * `GA_CODE`

# Version 0.5.2

This is a hotfix to fix occasional problems importing public body CSVs

# Version 0.5.1

## Highlighted features

This release was mainly to address issue #418, a regression introduced
in 0.5, which was causing deployment problems:

* Setting `STAGING_SITE: 0` in `general.yml` and running
  `script/rails-post-deploy` will ensure the correct behaviour in
  production environments
* It should now be safe to run `rake spec` on a production server

There is one minor new feature in this release:

* Administrators can follow the auto-login URLs forwarded in emails
  from users who want support, and they will remain logged in as
  themselves.

We now have a most of a Czech translation (thanks Josef Pospisil!)

Finally, this release also addresses a number of small bugs, including
the (potentially) important issue #408.

As usual, there is a [full list of changes on github](https://github.com/mysociety/alaveteli/issues?milestone=9&state=closed)

## Upgrade notes

* On a production server, ensure that `STAGING_SITE` is set to `0`,
  and then run `script/rails-post-deploy` as usual.

# Version 0.5

## Highlighted features
* It should now be possible to develop the software on OSX
* Base design refactored: CSS simplified and reduced, base design colours removed, now provided in example Alaveteli theme override
* It is now possible to rebuild the xapian index for specific terms, rather than having to drop and rebuild the entire database every time (as previously).  See rake xapian:rebuild_index for more info.
* When listing authorities, show all authorities in default locale, rather than only those in the currently selected locale.
* Ensure incoming emails are only ever parsed once (should give a performance boost)
* Added a simple rate-limiting feature: restrict the number of requests users can make per day, except if explicitly unrestricted in the admin interface
* [Full list of changes on github](https://github.com/mysociety/alaveteli/issues?state=closed&milestone=9)

## Upgrade notes
* **IMPORTANT! We now depend on Xapian 1.2**, which means you may need to install Xapian from backports.  See [issue #159](https://github.com/mysociety/alaveteli/issues/159) for more info.
* Themes created for 0.4 and below should be changed to match the new format (although the old way should continue to work):
  * You should create a resources folder at `<yourtheme>/public/` and symlink to it from the main rails app.  See the `install.rb` in `alaveteli-theme` example theme for details.
  * Your styles should be moved from `general/custom_css.rhtml` to a standalone stylesheet in `<yourtheme>/public/stylesheets/`
  * The partial at `general/_before_head_end.rhtml` should be changed in the theme to include this stylesheet
* [issue #281](https://github.com/mysociety/alaveteli/issues/281) fixes some bugs relating to display of internationalised emails.  To fix any wrongly displayed emails, you'll need to run the script at `script/clear-caches` so that the caches can be regenerated
* During this release, a bug was discovered in pdftk 1.44 which caused it to loop forever.  Until it's incorporated into an official release, you'll need to patch it yourself or use the Debian package compiled by mySociety (see link in [issue 305](https://github.com/mysociety/alaveteli/issues/305))
* Ensure you have values for new config variables (see `config/general.yml-example`):
  * EXCEPTION_NOTIFICATIONS_FROM
  * EXCEPTION_NOTIFICATIONS_TO
* The new optional config variable MAX_REQUESTS_PER_USER_PER_DAY can be set to limit the number of requests each user can make per day.
* The recommended Varnish config has changed, so that we ignore more cookies.  You should review your Varnish config with respect to the example at `config/varnish-alaveteli.vcl`.
* Consider setting elinks global config as described in the "Troubleshooting" section of INSTALL.md

# Version 0.4

## Highlighted features
* Complete overhaul of design, including improved search, modern look and feel, more twitter links, etc
* A banner alerts visitors from other countries to existing sites in their country, or exhorts them to make their own
* Bounce emails that result from user alerts are automatically processed and hard bouncing accounts do not continue to receive alerts.
  See the new instructions in INSTALL-exim4.md for details of how to set this up.
* Logged in users now have the ability to download a zipfile of the entire correspondence for a request
* Improved UI for responding to requests.  The user now has a single option to "reply" at the bottom of a request, and can adjust who they are replying to on the next page
* [Full list of changes on github](https://github.com/mysociety/alaveteli/issues?sort=created&direction=desc&state=closed&milestone=7)

## Upgrade notes
* Remember to `rake db:migrate` and `git submodule update`
* Ensure you have values for new config variables (see `config/general.yml-example`):
  * FORWARD_NONBOUNCE_RESPONSES_TO
  * TRACK_SENDER_EMAIL
  * TRACK_SENDER_NAME
  * HTML_TO_PDF_COMMAND
  * NEW_RESPONSE_REMINDER_AFTER_DAYS
  * FORCE_REGISTRATION_ON_NEW_REQUEST
* The config variable `FRONTPAGE_SEARCH_EXAMPLES` is no longer used, so you should remove it to avoid confusion.
* Execute `script/rebuild-xapian-index` to create new xapian index
  terms used in latest version of search (can take a long time)
* Install wkhtmltopdf to enable PDFs in downloadable zipfiles.  A
  static binary is recommended on Linux in order to run the command
  headless: http://code.google.com/p/wkhtmltopdf/downloads/list
* Ensure your webserver can serve up generated files by symlinking `cache/zips/download` to `public/download` (this is also done by the `rails-post-deploy` script).  If you're using Passenger + Apache, you'll need to add a `PassengerResolveSymlinksInDocumentRoot on` directive to the configuration.
  * Note that the zipfile download functionality will currently hang if you're running Alaveteli single-threaded, as it creates a new request to the server to get the print stylesheet version!
* Configure your MTA to handle bounce emails from alerts (see INSTALL-exim4.md)

# Version 0.3

## Highlighted features
* New search filters / UI on request page, authorities page, and search page.  Upgrades require a rebuild of the Xapian index (`./script/xapian-index-rebuild`).  Design isn't beautiful; to be fixed in next release.
* Introduce reCaptcha for people apparently coming from foreign countries (to combat spam) (requires values for new config variables `ISO_COUNTRY_CODE` and `GAZE_URL`, and existing config variables `RECAPTCHA_PUBLIC_KEY` and `RECAPTCHA_PRIVATE_KEY`)
* Better admin interface for editing multiple translations of a public body at once
## Other
* [Full list of changes on github](https://github.com/mysociety/alaveteli/issues?milestone=5&state=closed)
