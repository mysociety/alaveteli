# rails-3-develop

## Highlighted Features
* There is experimental support for using an STMP server, rather than sendmail,
  for outgoing mail. There is not yet any ability to retry if the SMTP server is
  unavailable.
* HTML 'widgets' advertising requests can be displayed on other sites in iframes.
  If 'ENABLE_WIDGETS' is set to true in `general.yml` (the default is false), a link
  to the widget code will appear in the right hand sidebar of a request page.
* Capistrano now caches themes (Henare Degan).
* Upgrades and fixes for security announcements CVE-2015-3225, CVE-2015-3227 and
  CVE-2015-1840 (Louise Crow).
* Attachment text conversion to UTF-8 is now handled in a clearer way by the
  `FoiAttachment` model. Censor rules are applied with the appropriate encoding
  (Louise Crow).
* A rake task `temp:fix_invalid_utf8` has been added to help people migrating an
  Alaveteli install from ruby 1.8.7 to a later ruby version (Louise Crow).
* An example wrapper script, `config/run-with-rbenv-path` has been added to run
  the mail scripts using the ruby version set by `rbenv`. Example code for this
  has also been added to the daemon and cron example files.

## Upgrade Notes

* Capistrano now caches themes in `shared/themes`. Run the `deploy:setup` task
  to create the shared directory before making a new code deploy.
* If you handle attachment text in your theme, note that:
    * `FoiAttachment#body` will always return a binary encoded string
    * `FoiAttachment#body_as_text` will always return a UTF-8 encoded string
    * `FoiAttachment#default_body` will return a UTF-8 encoded string for text
      content types, and a binary encoded string for all other types.

# Version 0.21

## Highlighted Features
* Lots of improvements in the process of making a new
  request (Martin Wright, Gareth Rees, Louise Crow):
  * Removal of confusing AJAX results in `/select_authority`.
  * Better layout of search/filtering options on the authority pages.
  * Better layout of the authority pages on smaller screens.
  * The dynamic list of possibly related requests for a new request
    is now limited to requests to the same authority and capped at
    three requests
  * 'Create a new account' option now more prominent than 'Sign in' on `/sign_in`
  * Better options for sharing your request on social media, and other
    actions to take once the request is made.
* Some general security improvements:
  * State changing admin actions are now restricted to PUT or POST methods
    to protect against CSRF attacks, and now use more standard RESTful
    routing (Louise Crow).
  * Global request forgery protection is now used (Gareth Rees).
  * Some standard security headers are added by default (Louise Crow).
  * A TTL is enforced on session cookies (Louise Crow).
* Added a new `AUTHORITY_MUST_RESPOND` configuration variable. Set this to
  `true` If authorities must respond by law. Set to `false` otherwise. It
  defaults to `true`. At the moment this just tweaks some UI text (Gareth Rees).
* New rake task for cleaning theme translations - `rake
  gettext:clean_theme` (Gareth Rees).
* There's a new admin interface for adding public holidays for the site,
  to be used in calculating request due dates. Documentation for using
  this interface is available at
  http://alaveteli.org/docs/installing/next_steps/#add-some-public-holidays (Louise Crow).
* Some interface phrases have been grouped together for easier
  translation (Gareth Rees, Louise Crow).
* Now using the bootstrap js files from the bootstrap-sass gem.
* Confusing 'web analytics' section of admin pages removed (Henare Degan)
* Banned users can no longer update their profile (Gareth Rees).
* The code that removes email addresses and mobile phone numbers from
  the public view of requests an responses has been refactored, and the
  text that's used to replace the email addresses and phone numbers can
  now be translated (Louise Crow).
* Fixed a bug with the CSV import of authorities which have the same
  name in multiple locales (Louise Crow).
* No longer need to restart webserver when compacting Xapian database (Gareth
  Rees).
* `config/deploy.yml` now accepts a `daemon_name` parameter so that Capistrano
  can deploy multiple Alaveteli instances on the same host (Gareth Rees).

## Upgrade notes

* Admin route names have been standardised so if you have overridden
  templates that refer to admin routes, check the original templates to
  see if these need to be changed. URLs in rreviously sent admin emails about
  requested changes to authorities will need to be tweaked to work - from
  `admin/body/new?change_request_id=n` to `admin/bodies/new?change_request_id=n`
* CSRF protection is now used by default on forms using 'POST', and as a result, the navbar and front page
  search forms have been converted to use 'GET' rather than 'POST'. If you override `/app/views/general/_frontpage_search_box.html.erb`, `app/views/general/header.html.erb` or `app/views/general/_responsive_topnav.html.erb`, you should update the search forms in your templates to use 'GET'. Any forms of your own
  that use the 'POST' method should be generated in Rails or otherwise include a CSRF token. If
  they don't, logged-in users will be logged out when they use them. 
* If you override the `app/views/user/_signin.html.erb` or
  `app/view/user/_signup.html.erb` templates, check the tabindex order
  is still sensible - the order of the elements on the page has changed
  - signup now appears on the left.
* If you override the application stylesheets rather than adding to them
  using a `custom.css` or `custom.scss` file, check that your
  stylesheets still order elements correctly in the templates
  `app/views/request/select_authority.html.erb`,
  `app/views/public_body/show.html.erb` and
  `app/views/request/new.html.erb`. Also, if you use the application
  stylesheets, but have overridden any of these templates or their partials, check to see
  if you need to update the order of elements in the templates.
* [Regenerate your crontab](http://alaveteli.org/docs/installing/manual_install/#generate-crontab)
  so that compacting the Xapian database only restarts the application, rather
  than the webserver. This requires the [appropriate SysVinit script](http://alaveteli.org/docs/installing/manual_install/#generate-application-daemon) to be installed.
* Alaveteli daemons must be executable by the app owner in a Capistrano setup.
  In a regular setup, the permissions should be `rwxr-xr-- root:alaveteli`.
* `config/sysvinit-thin.ugly` has been improved. Regenerate it with
  `rake config_files:convert_init_script`. See [the documentation](http://alaveteli.org/docs/installing/manual_install/#generate-application-daemon)
  for more information.
* This release includes an update to the commonlib submodule - you
  should be warned about this when running rails-post-deploy.

# Version 0.20

## Highlighted Features

* Upgrade compass-rails to version 2.0.0 (Louise Crow, Вальо)
* Added a fix to ensure attachments are rendered for emails sent with Apple Mail (Gareth Rees)
* Removed the authority preview from `/select_authority`. Clicking an authority now goes straight to the authority page (Gareth Rees)
* Allow closure of a change request without sending an email (Louise Crow)
* The sidebar in `app/views/public_body/show.html.erb` has been extracted to `app/views/public_body/_more_info.html.erb` to make overriding it in a theme easier (Gareth Rees)
* Allow resetting of the locale pattern on the locale routing filter (Louise Crow)
* Added filtering to the requests displayed on the user profile page (Gareth Rees)
* Add a Health Check page (Gareth Rees)
* Add a user interface for managing Public Body Categories (Liz Conlan, Louise Crow)
* Improve `CensorRule` validations. Please see Upgrade Notes if you have added or modified a `CensorRule` in your theme (Gareth Rees)
* Stop the `/blog` page throwing an exception if a correctly configured blog has no posts (Gareth Rees)
* Fixed a CSS issue with the authority preview container (Louise Crow)
* Sensible default values have been added to some configuration parameters. See upgrade notes for additional instruction (Gareth Rees)
* `general.yml-example` now contains full documentation and examples (Gareth Rees)
* CSV Import fields (for `/admin/body/import_csv`) are now configurable. This is useful if your theme adds additional attributes to `PublicBody` (Steven Day)

For example:

      # YOUR_THEME/lib/model_patches.rb
      # Extra fields can be appended to `csv_import_fields` in the format:
      # ['ATTRIBUTE_NAME', 'HELP_TEXT_DISPLAYED_IN_ADMIN_UI']
      #
      PublicBody.csv_import_fields << ['twitter_username', 'Do not include the @']

## Upgrade Notes

* Public body categories will now be stored in the database rather than being read directly from the `lib/public_body_categories_LOCALE` files. **Once you have upgraded, run `script/migrate-public-body-categories`to import the contents of the files into the database. All further changes will then need to be made via the administrative interface.** You can then remove any `pubic_body_categories_[locale].rb` files from your theme.  If your theme has any calls to `PublicBodyCategories` methods outside these files, you should update them to call the corresponding method on `PublicBodyCategory` instead.
* `OutgoingMessage#send_message` has been removed. We now perform email deliveries outside of the model layer in three steps:

Example:

    # Check the message is sendable
    if @outgoing_message.sendable?

        # Deliver the email
        mail_message = OutgoingMailer.initial_request(
            @outgoing_message.info_request,
            @outgoing_message
        ).deliver

        # Record the email delivery
        @outgoing_message.record_email_delivery(
            mail_message.to_addrs.join(', '),
            mail_message.message_id
        )
    end

See https://github.com/mysociety/alaveteli/pull/1889 for the full changes and feel free to ask on the [developer mailing list](https://groups.google.com/forum/#!forum/alaveteli-dev) if this change causes a problem.
* `MTA_LOG_PATH` now has a default value of `'/var/log/exim4/exim-mainlog-*'`. Check that your `MTA_LOG_PATH` setting is configured to the path where your mail logs are stored.
* `MAX_REQUESTS_PER_USER_PER_DAY` now has a default value of `6`. If you do not have a value set in `config/general.yml` you will need to set it to match your existing configuration. If you do not a `MAX_REQUESTS_PER_USER_PER_DAY` limit, set the value to an empty string (`''`).
* `INCOMING_EMAIL_PREFIX` now has a default of `'foi+'`. If you do not have a value set in `config/general.yml` you will need to set it to match your existing configuration. If you do not want an `INCOMING_EMAIL_PREFIX`,  set the value to an empty string (`''`, the previous default).

* An `admin` prefix has been added to the `:spam_addresses` resources. If you have used one of these paths in your theme, prefix the named route helper with `admin_`.
* `CensorRule` now validates the presence of all attributes at the model layer,
  rather than only as a database constraint. If you have added a `CensorRule` in
  your theme, you will now have to satisfy the additional validations on the
  `:replacement`, `:last_edit_comment` and `:last_edit_editor` attributes.
* `CensorRule#require_user_request_or_public_body`, `CensorRule#make_regexp` and
  `CensorRule#require_valid_regexp` have become private methods. If you override
  them in your theme, ensure they are preceded by the `private` keyword.

# Version 0.19

## Highlighted Features

* Improved documentation at http://alaveteli.org/docs (Louise Crow, Gareth Rees,
  Dave Whiteland)
* Added mySociety Launchpad PPA to supply updated version of pdftk (Louise Crow)
* Made default maintenance page generic (Gareth Rees)
* Support additional Vagrant operating system images (Gareth Rees)
* Add SysVinit for Phusion Passenger (Gareth Rees)
* Eager loading to speed up `body_request_events` API action (Louise Crow)
* Ability to update the status of external requests made via the API (Liz
  Conlan)
* Removed more mySociety internal dependencies from install script and example configuration and template files (Gareth Rees)
* Improved example configuration files (Gareth Rees)
* Support Portugese locale (Louise Crow)
* Default to using UTF-8 encoded database for new installs and CI (Gareth Rees)
* Better config file generators in `lib/tasks/config_files.rake` (Gareth Rees)
* Improved search term highlighting (Gareth Rees)
* Added responsive styling (Louise Crow)
* Documentation tidying and redirection (Louise Crow)
* Allow a message with more than one event to be destroyed (Louise Crow)
* Makes public body stats available if configured (Gareth Rees)
* Cache-busting on request response notification emails (Gareth Rees)
* Better error handling on new requests (Louise Crow)
* Rake task for cleaning up holding pen events (`rake cleanup:holding_pen`)
  (Louise Crow)
* Added searching of bodies by short_name (Gareth Rees)
* Additional stats on `/version.json` (Gareth Rees)
* Minor tweaks to the homepage (Gareth Rees)
* Translation housekeeping (Louise Crow)
* Minor style updates to admin request edit page (Gareth Rees)

## Upgrade Notes

* `HighlightHelper#excerpt` backports the Rails 4 `excerpt` which requires a
  Hash for the options parameter rather than globbing the remaining arguments.

For example:

    - <%=h excerpt(info_request.initial_request_text, "", 100) %>
    + <%=h excerpt(info_request.initial_request_text, "", :radius => 100) %>

You will need to update any use of `excerpt` in your theme to use the Hash args.

* Ubuntu Precise users can get an updated version of pdftk from mySociety's PPA

Install the repo and update the sources:

    apt-get install python-software-properties
    add-apt-repository ppa:mysociety/alaveteli
    apt-get update

The mySociety pdftk package (`1.44-7~precise1ms1`) should now be the install
candidate:

    apt-cache policy pdftk

* Install `lockfile-progs` so that the `run-with-lockfile` shell script can be
  used instead of the C program
* Use responsive stylesheets in `config/general.yml`:
  `RESPONSIVE_STYLING: true`. If you don't currently use responsive styling,
  and you don't want to get switched over just set `RESPONSIVE_STYLING: false`
  and the fixed-width stylesheets will be used as before.
* Allow access to public body stats page if desired in `config/general/yml`:
  `PUBLIC_BODY_STATISTICS_PAGE: true`
* Run migrations to define track_things constraint correctly (Robin Houston) and
  add additional index for `event_type` on `info_request_events` (Steven Day)
* The `SHARED_DIRECTORIES` setting now includes `tmp/pids`. The notes below for
  updating the log directory should cover the update steps for `tmp/pids`.
* Capistrano now creates `SHARED_PATH/tmp/pids` and links `APP_ROOT/tmp/pids`
  here, as the alert tracks daemon writes its pids to the generally expected
  location of `APP_ROOT/tmp/pids`.
* rails-post-deploy no longer handles linking `APP_ROOT/log` to a log directory
  outside the app. Capistrano users will find that `:symlink_configuration` now
  links `APP_ROOT/log` to `SHARED_PATH/log`. Users who aleady use the
  `SHARED_FILES` and `SHARED_DIRECTORIES` settings in `config/general.yml`
  should add `log/` to the `SHARED_DIRECTORIES` setting. The existing mechanism
  for shared directories (in `script/rails-deploy-before-down`) will create the
  necessary link to `SHARED_FILES_PATH/log`. If your existing shared log
  directory is not at `SHARED_FILES_PATH/log`, move the directory and re-run
  `script/rails-post-deploy` to link up the new location. If you don't use
  `SHARED_FILES` and `SHARED_DIRECTORIES`, alaveteli will now write it's
  application logs to `APP_ROOT/log` rather than `APP_ROOT/../logs` by default.
* `public_body_change_requests/new.html.erb` has a new field for spam prevention
  so customisations of this template should be updated with:

    <p style="display:none;">
      <%= label_tag 'public_body_change_request[comment]', _('Do not fill in this field') %>
      <%= text_field_tag 'public_body_change_request[comment]' %>
    </p>
  This is the anti-spam honeypot.
*  The workaround for an old [bug](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=637239) in libc6 in squeeze has been removed. If you're running on squeeze, please make sure you're using the latest version of libc6 (2.11.3-4) to prevent the risk of segfaults.
* The capistrano `stop`, `start` and `restart` tasks now restart the app
  server via the service `/etc/init.d/alaveteli`. If you're using
  capistrano for deployment, make sure `/etc/init.d/alaveteli` exists
  and is current, and executable by the cap user. You can create it using the template
  `config/sysvinit-thin.ugly` or `config/sysvinit-passenger.ugly` as
  described in http://alaveteli.org/docs/installing/manual_install/#generate-alaveteli-service
* This release includes an update to the commonlib submodule - you
  should be warned about this when running rails-post-deploy.

# Version 0.18

## Highlighted features

* There is an alternative set of stylesheets and header and footer
  templates for rendering the site in a stripped-down, responsive way
  (so that it will display appropriately on mobile devices as well as
  larger screens). This can be customised in a theme. We'll be adding
  some corresponding stylesheets shortly to alavetelitheme to provide a
  nice basic look and feel that can be customised. Eventually these
  responsive stylesheets will become the default (Louise Crow).
* Improvements in the Vagrant file (update to v2 API, configuration of
  FQDN, VirtualBox memory, development environment, better
  documentation) (Gareth Rees)
* Full date/time of correspondence now displayed on hover (Gareth Rees)
* Admins can now hide annotations in bulk from the admin interface
  (Andrew Black)
* Admins can now mark non-request email addresses as spam-targets if
  they are only receiving spam, so that email sent to these addresses no
  longer shows up in the holding pen, but is silently discarded (Gareth
  Rees)
* The contact form now has an anti-spam honeypot, and prevents double
  submission (Gareth Rees)
* Improvements to some translatable strings so that they're not composed
  on the fly according to English grammar (Louise Crow)
* Fixed bugs in text conversion under Ruby 1.9 (Rowan Crawford),
  handling of messages directing people to other instances of Alaveteli
  (Louise Crow), link-to-this popup location, 404 handling, comments on
  requests that are closed to comments, missing title tags in HTML
  attachments, PDF conversion and public body batch updates (Gareth
  Rees).

## Upgrade notes

* To use the responsive stylesheets across the site, add
  `RESPONSIVE_STYLING: true` to general.yml. To preview the way a given
  page would appear with the new stylesheets, add the parameter
  `responsive=1` to the URL.
* Theme owners are required to update references to fancybox CSS and JS
  files.
Example:

    - <%= javascript_include_tag 'jquery.fancybox-1.3.4.pack.js' %>
    + <%= javascript_include_tag 'fancybox.js' %>

    - <%= stylesheet_link_tag 'jquery.fancybox-1.3.4.css', :rel => "stylesheet"
    + <%= stylesheet_link_tag 'fancybox.css', :rel => "stylesheet"  %>
* There are some new strings in this release for translation, so if your
  site isn't in English, make sure your translations are up to date
  before deploying to production
* If your theme overrides the help/contact template, you should
  add elements to the form to match those added to the main template:

    <p style="display:none;">
        <%= f.label :comment, 'Do not fill in this field' %>
        <%= f.text_field :comment %>
    </p>
  This is the anti-spam honeypot.

# Version 0.17

## Highlighted features

* There is some initial support for making a request to multiple
  authorities at once.
* There is a new form for users to request that a new authority should
  be added, or to request an update to the contact email used for an
  authority. Site admins are emailed about these requests, and can
  resolve them from the admin interface.
* For attachments where we rely on Google Document Viewer to display the
  HTML version, link to the HTTPS version where the Alaveteli site is
  served over HTTPS to avoid mixed content warnings and non display in
  some browsers (Matthew Somerville).
* The 'view requests' page now has some fragment caching backed by
  memcached to speed up serving commonly used lists of requests - e.g
  all successful requests. Like the caching introduced in release 0.16,
  this is controlled by the `CACHE_FRAGMENTS` parameter in the config
  file and will be on by default.
* A user's annotations can now be seen on their admin page (Andrew
  Black)
* Better detection of the quoted text of a previous email in the HTML
  parts of responses.
* Fixed bugs in the profile photos (György Peng), calendar translations
  (Mark Longair), the use of external utilities (Ian Chard), the
  internal admin authority locale handling (Mark Longair), badly formed
  attachment handling (Rowan Crawford).

## Upgrade notes

* To use the batch request functionality, set the `ALLOW_BATCH_REQUESTS`
  parameter to `true` in your config file. Once this is done, and the
  install has been restarted, any user for whom 'Can make batch
  requests' is checked in the admin interface should see a new link on
  the 'Select an authority' page that allows them to make a batch
  request.
* If your theme overrides the help/requesting template, you should
  update the link in the section on requesting new authorities so the
  link points to `<%= new_change_request_path %>` instead of `<%=
  help_contact_path %>`.
* If your site runs over HTTPS, some cached attachments may still
  contain links to Google Document Viewer with 'http', not 'https'. You
  can clear the cached attachments after upgrade, and they will be
  created with links that use the correct protocol.
* This release includes an update to the commonlib submodule - you
  should be warned about this when running rails-post-deploy.

# Version 0.16

## Highlighted features

* Upgrade of the Rails framework to 3.2.16
* Enabling the Rails asset pipeline for managing assets (more about the
  asset pipeline at http://guides.rubyonrails.org/asset_pipeline.html).
* The all authorities csv download now uses less system resources
* Ruby 2.0 is now included in the matrix of versions we run continuous
  integration tests against
* When using capistrano, the RAILS_ENV can now be explicitly set from
  deploy.yml
* The front page and request pages once more use fragment caching backed
  by memcached to speed up serving of slow parts of these pages
* The robots.txt file has been updated to allow crawling of response
  attachment files (in original and HTML versions)
* The `themes:install` rake task is kinder to developers; it no longer
  removes and reclones themes, destroying local changes, and it keeps
  themes as git repositories.
* Social media elements (the blog, twitter feed) are only included if
  the appropriate config variables (BLOG_FEED and TWITTER_USERNAME) have
  been populated.
* Some fixes to the treatment of hyphenated/underscored locales so that
  public body translations are consistently stored using the underscore
  format of the locale (so 'he_IL', not 'he-IL').
* The popup message elements for temporary notices and for letting users
  know about other sites have been made consistent and now use simpler
  styles.

## Upgrade notes

* You will need to update your theme to use the asset pipeline - notes
  on how to do this are in doc/THEME-ASSETS-UPGRADE.md
* The syntax of the highlight and excerpt methods has changed, so if you
  use these in your theme, you may see deprecation warnings until you
  update them. More information at http://apidock.com/rails/v3.2.13/ActionView/Helpers/TextHelper/highlight
  and
  http://apidock.com/rails/v3.2.13/ActionView/Helpers/TextHelper/excerpt
* If you don't want to use fragment caching, you can turn it off in your
  config file by setting `CACHE_FRAGMENTS` to `false`.
* If you use a locale with an underscore in it, you should double check
  that the locale field of your `public_body_translations` table shows
  the underscore version of the locale name.
* This release includes an update to the commonlib submodule - you
  should be warned about this when running rails-post-deploy
* All code has been moved out of the deprecated plugin path
  `vendor/plugins`. Once you are up and running under 0.16, you should
  check that your xapian databases have all been copied to
  `lib/acts_as_xapian/xapiandbs` (the code in
  `config/initializers/acts_as_xapian` should do this), and then check
  and remove any files under vendor/plugins so that you won't get
  deprecation warnings about having Rails 2.3 style plugins (deprecation
  warnings can result in incoming mail getting an auto reply under some
  email configs).
* If you have any custom styles that rely on the absolute positioning
  of the 'banner' and 'wrapper' elements, they may need to be updated.
* Cached HTML versions of attachments in cache/attachments_production/
  will have obsolete links to `/stylesheets/main.css` and
  `/images/navimg/logo-trans-small.png`. You can resolve these by either
  moving the cached attachments away and allowing them to be regenerated
  on demand, or by symlinking `public/stylesheets/main.css` to
  `public/assets/application.css` and
  `public/images/navimg/logo-trans-small.png` to
  `public/assets/navimg/logo-trans-small.png`.

#  Version 0.15

## Highlighted features

* A new install script for setting up Alaveteli automatically on
  a fresh Debian wheezy or Ubuntu precise server, and a
  Vagrantfile so that it can be easily invoked by `vagrant up`
* Salutations in outgoing messages now can contain regular
  expression special characters.
* The links to public bodies from the first letters of the
  alphabet now work properly in when the letter would be
  represented by multiple bytes in UTF-8.
* There are improvements to searching for public bodies and
  when the "ask us to add one" message is shown.
* There is a fix for the
  [long-standing error](https://github.com/mysociety/alaveteli/issues/555)
  about duplicate Xapian job creation.
* A new rake task for importing large numbers of public bodies
  from CSV files: `rake import:import_csv`.
* Various improvements to the public body statistics graphs,
  thanks to feedback from the WDTK volunteers.
* The new_relic gem has been updated (Matthew Landauer)
* An example nginx config file for running Alaveteli behind
  nginx: `config/nginx.conf.example`.
* There's now a simple script for switching between themes
  (`script/switch-theme.rb`) for developers who have to work on
  more than one jurisdiction's theme.

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
* If you would like to have a public body statistics page (this will be publicly available), set the `PUBLIC_BODY_STATISTICS_PAGE` param in general.yml to `true`. You should also add a new cron job based on the one in config/crontab-example `https://github.com/mysociety/alaveteli/blob/develop/config/crontab-example#L29` to update the public body stats each day.
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
