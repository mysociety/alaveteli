# develop

## Highlighted Features

* Fix search.png not being included in precompiled assets (Nigel Jones)
* Drop support for Debian Jessie (Gareth Rees)
* Highlight non-default states of "Prominence" in the admin
  interface (Gareth Rees)
* Fix bug were the header was displayed at the wrong width if the site only had
  one language configured (Martin Wright)
* Show the message from the user on the admin summary page for requests and
  comments which have been flagged as needing administrator attention (Liz Conlan)
* Log an event when a user reports a request and capture the message data
  supplied by the user when they report a request as needing administrator
  attention in the log (Liz Conlan)
* Uses the url_name instead of a numeric id when sending messages between users
  to prevent id guessing (Liz Conlan)
* Reopen closed requests to allow responses from anybody when a new followup
  message is sent, or an admin resends an outgoing message (Liz Conlan)
* Warn users when their request is getting too long (Zarino Zappia)
* Add a customisable email footer for emails sent to users (Liz Conlan)
* Add one-click unsubscribe to `TrackMailer`-generated email notifications
  (Gareth Rees)
* Use the original subject line when sending an email reply to a
  PublicBodyChangeRequest through the admin interface (Liz Conlan)
* Improve logic for showing contact options when making followups to a request
  (Liz Conlan)
* Add guessing from the subject line of an incoming email in the holding pen
  (Liz Conlan)
* Improve guessing from addresses with missing punctuation for incoming email in
  the holding pen (Liz Conlan)
* Improve guessing from malformed addresses for incoming email in the holding
  pen (Gareth Rees)
* Add a `USER_CONTACT_FORM_RECAPTCHA` config setting to show a reCAPTCHA
  on the user-to-user contact form if set to true (defaults to false)
  (Liz Conlan)
* Add a note to the top of the request page when a request thread is closed to
  further correspondence (Liz Conlan)
* Add an option to hide a request containing personal information (Gareth Rees)
* Prevent censor rules from being unintentionally made permanent when admins
  edit outgoing messages. Allow admins to see the unredacted outgoing message
  text on request's admin page and in the associated event log (Liz Conlan)
* Add a `CONTACT_FORM_RECAPTCHA` config setting to show a reCAPTCHA on the
  contact form if set to true (defaults to false). Needs a small code snippet -
  documented in the `general.yml-example` file to be added to the theme's
  contact form for the reCAPTCHA to be displayed correctly (Liz Conlan)
* Added support for Ubuntu 16.04 LTS (Xenial Xerus) (Graeme Porteous)

## Upgrade Notes

* The `hidden_incoming_message` factory has been removed. Use the `:hidden`
  _trait_ instead if you rely on this in theme specs. See
  https://github.com/thoughtbot/factory_bot/blob/v4.10.0/GETTING_STARTED.md#traits
  for more information on traits.
* We no longer support Debian Jessie. Please upgrade to Debian Stretch at the
  earliest opportinuity.
* The changes to the way dynamic routes work means that any themes that use
  the `help_general_url` helper will need to pass in `:template` instead of
  `:action`

# 0.32.0.0

## Highlighted Features

* Move the user menu and sign up/sign in links from the navigation bar to the
  header to allow space for longer navigation link translations (Martin Wright)
* Better duplicate request detection (Graeme Porteous)
* Strip leading and trailing whitespace when searching for users in the admin
  interface (Gareth Rees)
* Fall back to the theme's standard opengraph logo rather than the example pro
  logo from core if there's no opengraph-pro logo available in the theme
  (Liz Conlan)
* Don't show the pro blank slate message when the user has a saved draft (Graeme
  Porteous)
* Improve the pro blank slate/"Getting started" message (Martin Wright)
* Add message navigation buttons to pro request pages to make it easier to move
  through long request threads (Martin Wright)
* Make the pro sidebar sticky (Martin Wright)
* Improvements to the pro sidebar to make it easier for a pro user to see when
  a private request will be published from the request page (Martin Wright)
* Parse and display incoming email headers in the admin interface (Gareth Rees)
* Don't update the Atom feed timestamp if there are no events (Graeme Porteous)
* Fix padding around delivery status and hidden message containers (Martin
  Wright, Zarino Zappia)
* Fix vertical alignment of follower count for easier theme overrides (Martin
  Wright)
* Avoid drawing border under final attachment in list (Zarino Zappia)
* Better user menu behaviour with long names (Martin Wright)
* Add the ability to collapse the correspondence on the request page (Martin
  Wright)
* Fix clash between the action menu and the sidebar in the mobile view (Martin
  Wright)
* Add missing background colour for "awaiting classification" status message
  (Martin Wright)
* Better HTML encoding on new request and admin email forms (Liz Conlan)
* Add Google Analytics events for clicks for "Related requests" links (Zarino
  Zappia)
* Add support for the `foi_no` tag for authorities so that new requests can
  still be made while making it clearer that they are not obliged by law to
  respond (Liz Conlan)
* Add tooltip prompts and an "Are you sure?" dialogue on save to the admin
  interface when marking a request as "vexatious" or "not_foi" without hiding it
  using the prominence dropdown (Liz Conlan)
* Ability to blacklist known addresses that cannot be replied to (Gareth Rees)
* Ability to customise no-reply address Regexp (Gareth Rees)
* Extend time before closing requests to all responses (Gareth Rees)
* Add a footer to the Admin layout with useful links to alaveteli.org (Gareth
  Rees)
* Add user name spam checking (Gareth Rees)
* Run the full user spam check during signup rather than just checking the
  email domain (Liz Conlan)
* Improve the spam checker code, make it easier to reuse and enable it on the
  sign in page (Graeme Porteous)
* Make it quicker to ban users for spamming in admin interface (Gareth Rees)
* Limit the frequency that `PublicBody#updated_at` gets updated by unrelated
  changes to an associated `InfoRequest` (Gareth Rees)
* Add standard Rails timestamp columns to all tables (Gareth Rees)
* Fix broken migrations introduced in 0.30 (Gareth Rees)
* Destroy embargoes when the attached info request is destroyed (Gareth Rees)
* Fix case sensitivity bug in password reset form (Gareth Rees)
* Rename dangerous Xapian commands (Gareth Rees)
* Improved handling of Xapian indexing failures (Gareth Rees)
* Prioritise direct matches on `PublicBody#name` in search results (Liz Conlan,
  Gareth Rees)
* Fix double encoding of URL params for search (Gareth Rees)
* Log an `InfoRequestEvent` when updating response handling attributes in
  `InfoRequest.stop_new_responses_on_old_requests` (Gareth Rees)
* Show that a request is part of a batch on the request page in the admin
  interface (Gareth Rees)
* Improve batch sending - better checks for whether a batch has finished
  sending, allows batch sending to be resumed if it exits before completion
  (Graeme Porteous)
* Add "Rejected incoming count" do the request page in the admin interface
  (Gareth Rees)
* Highlight non-default states of "Allow new responses from" in the admin
  interface (Gareth Rees)
* Add collapse/expand to request correspondence (Zarino Zappia)
* Fix downloading a Zip of entire request when the request contains a resent
  message (Gareth Rees)
* Add Pro opengraph logo (Martin Wright)
* Create site-wide and user role announcements from within the administrative
  interface (Graeme Porteous)
* Increase minimum password length for new users or updated passwords
  (Graeme Porteous)
* Improve password encryption by switching to bcrypt algorithm, existing
  password hashes will be upgraded when a user signs in (Graeme Porteous)
* Restore translated attributes to Public Body admin view (Gareth Rees)
* Updates the addresses of the OS base boxes in the Vagrantfile
* Various improvements to the test suite (Gareth Rees, Graeme Porteous, Liz Conlan)

## Upgrade Notes

* We've removed the spring preloader so run `bundle exec spring stop` before
  switching away from your current git branch otherwise you might see some odd
  code caching effects (if you're happy managing processes manually, you can
  find and kill the spring processes yourself instead)
* There are some database structure updates so remember to run `bundle exec rake db:migrate`
* Run `bundle exec rake temp:populate_missing_timestamps` to populate the new
  timestamp columns.
* You'll need to reindex your public bodies to benefit from the improved direct
  match results:
  `bundle exec rake reindex:public_bodies verbose="true"`
* Run `bundle exec rake users:update_hashed_password` to improve password
  encryption for existing users. As we don't know the original passwords this
  double encrypts the old SHA1 hash using the bcrypt algorithm.
* The reCAPTCHA config settings have changed, `RECAPTCHA_PUBLIC_KEY` is now
`RECAPTCHA_SITE_KEY` and `RECAPTCHA_PRIVATE_KEY` has changed to `RECAPTCHA_SECRET_KEY`
* The `BLOCK_SPAM_EMAIL_DOMAINS` config setting has been renamed to `BLOCK_SPAM_SIGNUPS` to reflect the change in functionality (it will now also run the full spam checker against the new user data rather than just looking at the email domain)
* The "very old" calculation driven by
  `RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS` has been increased from
  `2 *` to `4 *`. Please check that this config value is acceptable for your
  site's usage profile.
* Add a 256x256 image named `logo-opengraph-pro.png` to
  `YOUR_THEME_ROOT/assets/images`, to be shown next to pages from your site when
  shared on Facebook. You can just duplicate `logo-opengraph.png` if you don't
  have specific Pro branding.
* `InfoRequest.get_last_event` is deprecated and will be removed in 0.33. Please
  use `InfoRequest.last_event`.
* Xapian's `rebuild_index` is now called `destroy_and_rebuild_index`.
* The no-reply address handling can be customised in your theme. You can do this
  in `lib/model_patches.rb` by assigning a `Regexp` of your choice to
  `ReplyToAddressValidator.no_reply_regexp`. e.g.
  `ReplyToAddressValidator.no_reply_regexp = /hello/`. Note that this only acts
  on the local part of an email address (before the `@`) rather than the full
  address.
* A list of addresses that are known to cause problems when replying to them can
  be set by assigning an Array of addresses to
  `ReplyToAddressValidator.invalid_reply_addresses` in `lib/model_patches.rb`.
  e.g: `ReplyToAddressValidator.invalid_reply_addresses = %w(a@example.com)`.
* FactoryGirl is now called FactoryBot so you may need to update your test code
  accordingly.
* We've removed the Foundation gem as we're no longer using it so you will need
  to edit your theme code if you've relied on Foundation for any customisation.
* This release includes an update to the commonlib submodule - you
  should be warned about this when running `rails-post-deploy`.

### Changed Templates

    app/views/admin_general/_admin_navbar.html.erb
    app/views/admin_general/index.html.erb
    app/views/admin_incoming_message/_actions.html.erb
    app/views/admin_public_body/_form.html.erb
    app/views/admin_raw_email/show.html.erb
    app/views/admin_request/edit.html.erb
    app/views/admin_request/hidden_user_explanation.text.erb
    app/views/admin_request/show.html.erb
    app/views/admin_user/_user_table.html.erb
    app/views/admin_user/show.html.erb
    app/views/alaveteli_pro/account_request/index.html.erb
    app/views/alaveteli_pro/batch_request_authority_searches/_add_authority_to_draft_button.html.erb
    app/views/alaveteli_pro/batch_request_authority_searches/_remove_authority_from_draft_button.html.erb
    app/views/alaveteli_pro/batch_request_authority_searches/_search_result.html.erb
    app/views/alaveteli_pro/batch_request_authority_searches/_search_results.html.erb
    app/views/alaveteli_pro/batch_request_authority_searches/index.html.erb
    app/views/alaveteli_pro/dashboard/_no_to_dos.html.erb
    app/views/alaveteli_pro/dashboard/index.html.erb
    app/views/alaveteli_pro/draft_info_request_batches/_summary.html.erb
    app/views/alaveteli_pro/general/_nav_items.html.erb
    app/views/alaveteli_pro/info_request_batches/_embargo_form.html.erb
    app/views/alaveteli_pro/info_request_batches/_embargo_info.html.erb
    app/views/alaveteli_pro/info_request_batches/_info_request_batch.html.erb
    app/views/alaveteli_pro/info_request_batches/_message_preview.html.erb
    app/views/alaveteli_pro/info_requests/_after_actions.html.erb
    app/views/alaveteli_pro/info_requests/_embargo_extension_form.html.erb
    app/views/alaveteli_pro/info_requests/_embargo_form.html.erb
    app/views/alaveteli_pro/info_requests/_embargo_info.html.erb
    app/views/alaveteli_pro/info_requests/_message_preview.html.erb
    app/views/alaveteli_pro/info_requests/_no_requests.html.erb
    app/views/alaveteli_pro/info_requests/_sidebar.html.erb
    app/views/alaveteli_pro/info_requests/index.html.erb
    app/views/alaveteli_pro/plans/index.html.erb
    app/views/alaveteli_pro/plans/show.html.erb
    app/views/alaveteli_pro/subscriptions/index.html.erb
    app/views/api/request_events.atom.builder
    app/views/followups/_followup.html.erb
    app/views/general/_log_in_bar.html.erb
    app/views/general/_opengraph_tags.html.erb
    app/views/general/_popup_banner.html.erb
    app/views/general/_responsive_header.html.erb
    app/views/general/_responsive_stylesheets.html.erb
    app/views/general/_responsive_topnav.html.erb
    app/views/info_request_batch/show.html.erb
    app/views/layouts/admin.html.erb
    app/views/layouts/default.html.erb
    app/views/notification_mailer/info_requests/messages/_very_overdue.text.erb
    app/views/notification_mailer/very_overdue_notification.text.erb
    app/views/public_body/show.html.erb
    app/views/reports/new.html.erb
    app/views/request/_after_actions.html.erb
    app/views/request/_incoming_correspondence.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_request_subtitle.html.erb
    app/views/request/describe_notices/_waiting_response.html.erb
    app/views/request/describe_notices/_waiting_response_overdue.html.erb
    app/views/request/details.html.erb
    app/views/request/new.html.erb
    app/views/request/show.text.erb
    app/views/request_mailer/very_overdue_alert.text.erb
    app/views/user/_show_user_info.html.erb
    app/views/user/_signup.html.erb
    app/views/user/rate_limited.html.erb
    app/views/user/set_draft_profile_photo.html.erb
    app/views/user/set_profile_about_me.html.erb
    app/views/user/show/_show_profile.html.erb
    app/views/user_profile/about_me/edit.html.erb

# 0.31.0.4

## Highlighted Features

* Updated translations from Transifex (Liz Conlan)

# 0.31.0.3

## Highlighted Features

* Fix broken translation string (Gareth Rees)

# 0.31.0.2

## Highlighted Features

* Remove obsolete pro msgids (Gareth Rees)

# 0.31.0.1

## Highlighted Features

* Updated translations from Transifex (Gareth Rees)

# 0.31.0.0

## Highlighted Features

* Rescue from POP poller timeouts (Graeme Porteous)
* Fixed issue where an attempted password reset with cookies disabled caused a
  redirect loop (Graeme Porteous)
* Improved user drop down positioning (Martin Wright)
* Fixed an issue where selectize was blocking other scripts from running
  (Graeme Porteous)
* Dropped support for Ruby 1.9 (Liz Conlan)
* Default to Ruby 2.x for all install scripts (Liz Conlan)
* Removed support for Debian Wheezy (Liz Conlan)
* Add Debian Stretch support (Louise Crow, Gareth Rees)
* Replace out of support zip gem with rubyzip to address an issue where some
  zip files created by the site may not be openable on Windows PCs (Liz Conlan,
  Graeme Porteous)
* Fix bug in `stats:show` task (Liz Conlan, Gareth Rees)
* Use `.eml` file extension when downloading raw emails through the admin
  interface (Gareth Rees)
* Reduce usage of auto-login links in emails (Gareth Rees)
* Remove rendering of exceptions in admin interface (Gareth Rees)
* Pass through sign-in form if a user is already signed in (Gareth Rees)
* Make the event history table responsive (Miroslav Schlossberg)
* Fix bug that prevented private requests from being published across the whole
  site once the embargo period had expired (Liz Conlan)
* Update format of `robots.txt` for Baidu compatibility (Gareth Rees)
* Removed support for Ubuntu Precise (Louise Crow)
* Remove the use of purge requests to Varnish (Louise Crow)
* Add a temp task to recache any attachments whose content has changed
  (Louise Crow)

## Upgrade Notes

* This release drops support for Ruby 1.9.x. If you are using Ubuntu Trusty you
  will need to install a newer ruby version either using a ruby environment
  manager like [rbenv](https://github.com/rbenv/rbenv#basic-github-checkout) or
  by installing the ruby2.1 (and ruby2.1-dev) or ruby2.3 (and ruby2.3-dev)
  [Ubuntu packages from Brightbox](https://www.brightbox.com/docs/ruby/ubuntu/).
  (If you are setting up a fresh Trusty box using our script, the 2.1 Brightbox
  package is supplied.)

* Please note that this release removes support for Ubuntu Precise as it has
  reached End of Life and will no longer receive security patches. If you are
  running Alaveteli on Ubuntu Precise, you should upgrade your OS to
  Ubuntu Trusty before upgrading to this release. This
  [Ubuntu upgrade guide](https://wiki.ubuntu.com/TrustyTahr/ReleaseNotes#Upgrading_from_Ubuntu_12.04_LTS_or_Ubuntu_13.10)
  can guide you through the process. If you have
  questions about upgrading OS, please don't hesitate to ask on the
  [alaveteli-dev](https://groups.google.com/forum/#!forum/alaveteli-dev) group.

* Please note that this release also removes support for Debian Wheezy as it
  only packages Ruby 1.9.3. If you are running Alaveteli on Debian Wheezy, you
  should upgrade your OS to Debian Jessie before upgrading to this release. This
  [Debian upgrade guide](https://www.debian.org/releases/jessie/amd64/release-notes/ch-upgrading.en.html)
  can guide you through the process. If you have questions about upgrading OS,
  please don't hesitate to ask on the [alaveteli-dev](https://groups.google.com/forum/#!forum/alaveteli-dev) group.

* This release removes the use of purge requests to Varnish. Please make sure
  your site works with `VARNISH_HOST` empty before upgrading.

* There's a new temp task that can be used to recache any attachments whose
  content has slightly changed (e.g. due to an upgrade in the `mail` gem that
  alters e.g the trailing space on attachment bodies). You can run it with
  `bundle exec rake temp:populate_missing_attachment_files` if you're seeing
  `No such file or directory @ rb_sysopen` errors from `foi_attachment.rb`.

* There are some database structure updates so remember to `rake db:migrate`

### Changed Templates

    app/views/admin_general/_to_do_list.html.erb
    app/views/admin_general/index.html.erb
    app/views/admin_raw_email/show.html.erb
    app/views/admin_request/show.html.erb
    app/views/admin_user/show.html.erb
    app/views/alaveteli_pro/account_request/new.html.erb
    app/views/alaveteli_pro/batch_request_authority_searches/index.html.erb
    app/views/alaveteli_pro/dashboard/_projects.html.erb
    app/views/alaveteli_pro/dashboard/index.html.erb
    app/views/alaveteli_pro/general/_log_in_bar_links.html.erb
    app/views/alaveteli_pro/info_request_batches/_embargo_form.html.erb
    app/views/alaveteli_pro/info_request_batches/_embargo_info.html.erb
    app/views/alaveteli_pro/info_request_batches/_form.html.erb
    app/views/alaveteli_pro/info_request_batches/_info_request.html.erb
    app/views/alaveteli_pro/info_requests/_embargo_form.html.erb
    app/views/alaveteli_pro/info_requests/_embargo_info.html.erb
    app/views/alaveteli_pro/info_requests/_form.html.erb
    app/views/alaveteli_pro/info_requests/_info_request.html.erb
    app/views/alaveteli_pro/info_requests/_new_request_advice.html.erb
    app/views/alaveteli_pro/info_requests/_select_authority_form.html.erb
    app/views/alaveteli_pro/info_requests/_sidebar.html.erb
    app/views/alaveteli_pro/info_requests/index.html.erb
    app/views/alaveteli_pro/info_requests/new.html.erb
    app/views/alaveteli_pro/info_requests/preview.html.erb
    app/views/general/_frontpage_bodies_list.html.erb
    app/views/general/_frontpage_requests_list.html.erb
    app/views/general/_log_in_bar.html.erb
    app/views/general/_responsive_footer.html.erb
    app/views/general/exception_caught.html.erb
    app/views/notification_mailer/info_request_batches/messages/_overdue.text.erb
    app/views/notification_mailer/info_request_batches/messages/_very_overdue.text.erb
    app/views/notification_mailer/info_requests/messages/_overdue.text.erb
    app/views/notification_mailer/info_requests/messages/_very_overdue.text.erb
    app/views/outgoing_mailer/_followup_footer.text.erb
    app/views/password_changes/new.html.erb
    app/views/request/_act.html.erb
    app/views/request/_request_listing_single.html.erb
    app/views/request/_request_listing_via_event.html.erb
    app/views/request/_request_sent.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/details.html.erb
    app/views/request/show.html.erb
    app/views/track/_rss_feed.html.erb
    app/views/user/_signin.html.erb
    app/views/user/_signup.html.erb
    app/views/user/show.html.erb
    app/views/user/sign.html.erb
    app/views/users/sessions/show.html.erb

# 0.30.0.5

## Highlighted Features

* Updated translations from Transifex (Liz Conlan)

# 0.30.0.4

## Highlighted Features

* Updated translations from Transifex (Liz Conlan)

# 0.30.0.3

## Highlighted Features

* Updated translations from Transifex (Liz Conlan)
* New pro strings for translation (Liz Conlan)

# 0.30.0.2

## Highlighted Features

* Added a fix for the holiday imports admin tool (Liz Conlan)

# 0.30.0.1

## Highlighted Features

* Moved `rake temp:set_daily_summary_times` from upgrade notes
  for release 0.29.0.0 to release 0.30.0.0 (Louise Crow)

# 0.30.0.0

## Highlighted Features

* Added some extra margin space to the `#logged_in_bar` when javascript is
  disabled to avoid the user's name from overlapping the 'Sign out' link -
  otherwise if there is enough space to do so, the secondary menu will try to
  float alongside the nav bar content (Liz Conlan)
* Make it clearer to users that they must complete an action when receiving the
  email to remind them to update the status of a request (Gareth Rees)
* Removed non-responsive assets (Gareth Rees)
* Upgrade to Rails 4.2 (Liz Conlan, Gareth Rees)
* Fixed problem where the routing filter doesn't recognise default locales with
  underscores properly (Liz Conlan)
* Added wrapper methods to `AlaveteliLocalization` to be used in preference to
  the underlying `I18n` and `FastGettext` methods, avoiding confusion about
  which should be used and reducing the likelihood of getting hyphenated and
  underscore locale formats mixed up (Liz Conlan)
* Prevent null bytes getting saved to `IncomingMessage` attachment cache
  columns (Gareth Rees)
* Add `:inverse_of` option to ActiveRecord associations to improve performance
  (Gareth Rees)
* Make Vagrant settings configurable through `.vagrant.yml` (Gareth Rees)
* Make sure geoip-database-contrib is installed when installing Alaveteli
  (Gareth Rees)
* Make sure memcached is installed when installing Alaveteli (Gareth Rees)
* Remove front-end caching from delivery status calculation (Gareth Rees)
* Remove unconventional PublicBody database constraints (Gareth Rees,
  Liz Conlan)
* Improve public body data validations (Gareth Rees)
* Increase truncation length of comments on admin page so that its easier to
  spot spam without expanding each comment (Gareth Rees)
* Handle unicode in spam request subject lines (Gareth Rees)
* Improve public body data validation test coverage (Gareth Rees)
* Move some more flash messages to be rendered from partials (Gareth Rees)
* Admin timeline can now show events filtered by type (Louise Crow)
* As promised the `notifications_testers` role as been removed. Access to
  the experimental notification features is now controlled by a feature flag.
* Request numbers in search and list views are now more clearly displayed as
  estimates (Liz Conlan)
* Functionality of 'was clarification' admin button restored (Louise Crow)
* A new method for receiving incoming mail has been introduced. Setting the experimental
  config variable `PRODUCTION_MAILER_RETRIEVER_METHOD` to `pop` and generating
  a daemon from the `poll-for-incoming-debian.example` template will
  cause Alaveteli to poll a mailbox for incoming mail via POP, in addition to
  passively accepting mail piped into the application via `script/mailin` (Louise Crow)
* Only publicly visible requests are now counted in the text for a user search
  result (Louise Crow)
* Similar request IDs are now cached, rather than template partials displaying
  similar requests, in order to make better usage of the cache space (Louise Crow)
* You can now filter users by their role on the admin user list page (Louise Crow)
* Remove the obsolete `admin_level` user attribute (Louise Crow)
* Allow embargoed requests to be displayed separately in the admin interface
  to admins with pro_admin permissions (Louise Crow)
* Add a cookie_passthrough param to ensure that image files in responses can be
  accessed by authorised users on embargoed requests (Louise Crow)
* Add `oink` memory debugging setup. Use `ALAVETELI_USE_OINK=1` to produce
  object allocation debugging output (Louise Crow)

## Upgrade Notes

* This release removes the `admin_level` user attribute. You will need to migrate
  to this release via 0.29.0.0 and follow the instructions in the release notes for
  that release to migrate admin and pro statuses to the role-based system first, in
  order to retain admin status for your admin users.
* Ensure memcached is installed (`sudo apt-get install memcached`) and running
  (`sudo service memcached start`).
* `app/views/track/_track_set.erb` has been renamed to
  `app/views/track/_track_set.html.erb`, so if you've overriden it you will need
  to update the override.
* `app/views/general/_opengraph_tags.erb` has been renamed to
  `app/views/general/_opengraph_tags.html.erb`, so if you've overriden it you
  will need to update the override.
* Run `bundle exec rake temp:populate_last_event_time` after deployment to populate
  the cached `last_event_time` attribute on info_requests, used in the admin interface.
* Run `bundle exec rake temp:remove_notifications_tester_role` to remove the
  notification tester role from the database.
* Use of the `PRODUCTION_MAILER_RETRIEVER_METHOD` config setting is currently
  not recommended.
* Upgrading to Rails 4.2 requires that themes have a new section in their
  `alavetelitheme.rb` file as in:
  https://github.com/mysociety/whatdotheyknow-theme/commit/f99f7fd4538e57c2429ee2301317785c76eb08b0
  For more details, see the [preparatory changes](https://github.com/mysociety/alaveteli/pull/4124/commits)
  and [the upgrade itself](https://github.com/mysociety/alaveteli/pull/4114/commits)
* To start the Rails server from a Vagrant box, you will now need to tell it
  what address to bind to as it now defaults to localhost.
  e.g. `bundle exec rails s -b 0.0.0.0` to bind to all addresses (as before)
  or `bundle exec rails s -b 10.10.10.30` to just use the Vagrantfile address.
* File-type icons have been moved from `images` to `images/content_type`. Please
  ensure any direct use of these uses the new path.
* This release deprecates the use of purge requests to Varnish. Please make sure
  your site works with `VARNISH_HOST` empty - it will be removed as a param in
  the next release.
* Run `bundle exec rake temp:set_daily_summary_times` to set some default
  times for users to receive daily summaries of notifications. This won't have
  any effect on emails for most users until the new notifications system is
  rolled out.
* There are some database structure updates so remember to `rake db:migrate`

### Changed Templates

    app/views/admin_comment/index.html.erb
    app/views/admin_general/index.html.erb
    app/views/admin_general/timeline.html.erb
    app/views/admin_public_body/show.html.erb
    app/views/admin_user/index.html.erb
    app/views/alaveteli_pro/account_mailer/account_request.text.erb
    app/views/alaveteli_pro/account_request/new.html.erb
    app/views/alaveteli_pro/draft_info_request_batches/_draft_info_request_batch.html.erb
    app/views/alaveteli_pro/embargo_mailer/expiring_alert.text.erb
    app/views/alaveteli_pro/info_request_batches/_authority_list.html.erb
    app/views/alaveteli_pro/info_request_batches/_form.html.erb
    app/views/alaveteli_pro/info_request_batches/_info_request_batch.html.erb
    app/views/alaveteli_pro/info_requests/_after_actions.html.erb
    app/views/alaveteli_pro/info_requests/_info_request.html.erb
    app/views/alaveteli_pro/info_requests/_sidebar.html.erb
    app/views/alaveteli_pro/info_requests/preview.html.erb
    app/views/comment/preview.html.erb
    app/views/contact_mailer/update_public_body_email.text.erb
    app/views/followups/preview.html.erb
    app/views/general/_footer.html.erb
    app/views/general/_header.html.erb
    app/views/general/_opengraph_tags.html.erb
    app/views/general/_orglink.html.erb
    app/views/general/_responsive_header.html.erb
    app/views/general/_stylesheet_includes.html.erb
    app/views/general/_topnav.html.erb
    app/views/general/search.html.erb
    app/views/info_request_batch/show.html.erb
    app/views/layouts/default.html.erb
    app/views/layouts/no_chrome.html.erb
    app/views/public_body/_body_listing_single.html.erb
    app/views/public_body/_more_info.html.erb
    app/views/public_body/show.html.erb
    app/views/request/_after_actions.html.erb
    app/views/request/_bubble.html.erb
    app/views/request/_list_results.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/_view_html_stylesheet.html.erb
    app/views/request_mailer/new_response.text.erb
    app/views/track/_track_set.erb
    app/views/user/_user_listing_single.html.erb

# 0.29.0.2

## Highlighted Features

* Updated translations from Transifex (Louise Crow)

# 0.29.0.1

## Highlighted Features

* Fixed problem where the routing filter doesn't recognise default locales with
  underscores properly (Liz Conlan)
* Added wrapper methods to AlaveteliLocalization to be used in preference to the
  underlying I18n and FastGettext methods, avoiding confusion about which should
  be used and reducing the likelihood of getting hyphenated and underscore
  locale formats mixed up (Liz Conlan)

# 0.29.0.0

## Highlighted Features

* Upgrade to Rails 4.1 (Liz Conlan, Gareth Rees)
* Add sample public body headings and categories (Gareth Rees)
* Allow translation of delivery statuses (Gareth Rees)
* Fix stripping Syslog prefix from mail logs (Gareth Rees)
* Fix parsing of Syslog-format mail logs (Gareth Rees)
* Log spam domain signups instead of sending exception notifications
  (Gareth Rees)
* Finer control of anti-spam features (Gareth Rees)
* Fixed bug which redirected people trying to request a change to the email of
  a public body back to the missing body form post sign in (Liz Conlan)
* Tweak wording of bounce reply to make it easier for admins to locate the
  related request (Gareth Rees)
* Fix the layout of the request preview page so that the request body text is
  in line with the heading (Keerti Gautam)
* Add an unknown delivery status for better user experience when we haven't yet
  parsed MTA logs for a recent message (Gareth Rees)
* Switch MTA-specific delivery status to MTA-agnostic delivery status
  (Gareth Rees)
* Prevent deletion of initial outgoing messages through the admin interface
  (Gareth Rees)
* Make it easier to find the "Resend" message button in the admin interface
  (Gareth Rees)
* Install supported version of bundler through Rubygems on Debian Wheezy (Gareth
  Rees)
* Update Czechia country name in `WorldFOIWebsites` (Gareth Rees)
* Prevent null bytes getting saved to `IncomingMessage` cache columns (Gareth
  Rees)
* Add missing erb tags (Sam Smith)
* Introduction of role-based permissions system (Louise Crow)
* Link to the #internal_review section of the `help/unhappy` page instead of
  the UK-specific external link to FOIWiki (Liz Conlan)
* Allow comments to be reported for admin attention (Liz Conlan, Gareth Rees)
* Fix a bug in typeahead search where a search ending in a one or two letter
  word would automatically return zero results (Louise Crow)
* Update the spam scorer to hold lists of suspicious domains (email domains with
  a higher than average chance of being spam) and spam domains (email domains
  we're fairly confident are spam), and prevent spam domains from creating new
  accounts (Liz Conlan)
* Prevent the `/request/search_ahead` page from raising an error if there are
  no query parameters (Liz Conlan)
* Change "Send message" and "Send request" buttons to read "Send and publish" to
  make it clearer that your message is going to be shared via the website (Liz
  Conlan)
* Prevent new request titles from containing line breaks (Liz Conlan)
* Make the `users:stats_by_domain` task report percentages to 2 decimal places
  to avoid the situation where 374 out of 375 appears as 100% (Liz Conlan)
* Make `users:ban_by_domain` send a simpler message to say they've been banned
  rather than helping them work around our spam measures (Liz Conlan)
* A new role `notifications_testers` has been added, this is a temporary role
  to help us test new email configuration options for Alaveteli Professional,
  please don't give this role to any of your users - it may change and/or
  disappear without warning!
* Prevent Vagrant assigning more CPU cores than VirtualBox recognises (Liz
  Conlan)
* Improvements to the `load-sample-data` script to make it possible to run
  without the superuser db permissions and for Rails 4.1 compatibility
  (Liz Conlan)
* Prevent autoresponder emails from authorities resetting the withdrawn status
  on requests (Liz Conlan)
* Fix bug that prevented the categorisation game page from displaying when there
  are no requests (Liz Conlan)
* Switch to Trusty as the preferred OS for Travis CI and use Debian Wheezy as
  the new Vagrant default (Liz Conlan)
* Fix a bug that could cause misdelivered message links in the admin interface
  to appear without any text in the link if the message body contained unicode
  spaces (Liz Conlan)
* Use partial templates to render flash messages containing HTML rather than
  assigning the content directly to flash (Liz Conlan, Steven Day)
* Ensure info_requests are expired when censor rules are added, changed or
  removed (Liz Conlan)
* Fix the select authorities form when Javascript is disabled (Louise Crow)

## Upgrade Notes

* Spring is now used as the application preloader in development mode. No action
  required, but worth being familiar with if you're running Alaveteli in
  development: http://guides.rubyonrails.org/v4.1.16/upgrading_ruby_on_rails.html#spring
* The `COOKIE_STORE_SESSION_SECRET` config item has been removed and replaced
  with `SECRET_KEY_BASE`. You should migrate the original value to the new
  config key.
* Anti-spam feaures can now be enabled independently
  (`BLOCK_RATE_LIMITED_IPS`, `BLOCK_RESTRICTED_COUNTRY_IPS`,
  `BLOCK_SPAM_ABOUT_ME_TEXT`, `BLOCK_SPAM_COMMENTS`, `BLOCK_SPAM_EMAIL_DOMAINS`,
  `BLOCK_SPAM_REQUESTS`) or all at once (`ENABLE_ANTI_SPAM`). Check that your
  configuration is enabling the anti-spam measures that you're expecting.
* `MailServerLog::EximDeliveryStatus` and `MailServerLog::PostfixDeliveryStatus`
  have been deprecated in favour of an MTA-agnostic
  `MailServerLog::DeliveryStatus`. You should run
  `bundle exec rake temp:cache_delivery_status` to convert any cached delivery
  statuses to the new format.
* To migrate admin and pro statuses to the role-based system, you must run
  `bundle exec rake db:seed` and then
  `bundle exec rake temp:migrate_admins_and_pros_to_roles` after deployment.
* There are some database structure updates so remember to `rake db:migrate`
* Run `bundle exec rake temp:remove_line_breaks_from_request_titles` after
  deployment to remove stray line breaks (could effect Atom feeds)
* Run `bundle exec rake temp:generate_request_summaries` after deployment to
  create the new facade models that the Alaveteli Pro dashboard uses to
  display all forms of requests in a unified list.
* Run `bundle exec rake temp:set_use_notifications` after deployment to
  opt all existing requests out of the new notifications feature. This is VERY
  IMPORTANT to run, as without it, existing requests won't trigger any alert
  emails at all.
* The way that flash messages are rendered has changed so if you have overridden
  a template which renders flash (e.g. `<%= flash[:notice] %>`), you will need
  to use the new `<%= render_flash(flash[:notice]) %>` style instead.
* This release deprecates non-responsive stylesheets. Please make sure your site
  works with `RESPONSIVE_STYLING` set to `true`.
* This is likely to be the last release that supports Ruby 1.9.x. We have some
  [notes](https://git.io/vLNg0) on migrating away from 1.8.7; migrating to
  Ruby 2+ should be a similar process. Debian Jessie and Ubuntu 14.04+ include
  packaged versions of Ruby 2+.


### Changed Templates

    app/views/admin_comment/edit.html.erb
    app/views/admin_general/index.html.erb
    app/views/admin_general/timeline.html.erb
    app/views/admin_outgoing_message/edit.html.erb
    app/views/admin_public_body/show.html.erb
    app/views/admin_public_body_categories/_form.html.erb
    app/views/admin_request/_some_requests.html.erb
    app/views/admin_request/index.html.erb
    app/views/admin_request/show.html.erb
    app/views/admin_user/_form.html.erb
    app/views/admin_user/show.html.erb
    app/views/alaveteli_pro/comment/_suggestions.html.erb
    app/views/alaveteli_pro/dashboard/_activity_list_item.html.erb
    app/views/alaveteli_pro/dashboard/_projects.html.erb
    app/views/alaveteli_pro/dashboard/index.html.erb
    app/views/alaveteli_pro/draft_info_requests/_draft_info_request.html.erb
    app/views/alaveteli_pro/embargo_mailer/expiring_alert.text.erb
    app/views/alaveteli_pro/followups/_embargoed_form_title.html.erb
    app/views/alaveteli_pro/general/_log_in_bar_links.html.erb
    app/views/alaveteli_pro/info_requests/_embargo_info.html.erb
    app/views/alaveteli_pro/info_requests/_info_request.html.erb
    app/views/alaveteli_pro/info_requests/_request_list.html.erb
    app/views/alaveteli_pro/info_requests/_sidebar.html.erb
    app/views/alaveteli_pro/info_requests/new.html.erb
    app/views/alaveteli_pro/info_requests/preview.html.erb
    app/views/alaveteli_pro/public_bodies/_search_result.html.erb
    app/views/comment/_single_comment.html.erb
    app/views/followups/_followup.html.erb
    app/views/followups/preview.html.erb
    app/views/general/_log_in_bar.html.erb
    app/views/general/_nav_items.html.erb
    app/views/general/_responsive_header.html.erb
    app/views/general/_responsive_topnav.html.erb
    app/views/general/_topnav.html.erb
    app/views/layouts/admin.html.erb
    app/views/layouts/default.html.erb
    app/views/layouts/no_chrome.html.erb
    app/views/outgoing_messages/delivery_statuses/show.html.erb
    app/views/public_body/_list_sidebar_extra.html.erb
    app/views/public_body/_more_info.html.erb
    app/views/reports/new.html.erb
    app/views/request/_after_actions.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_request_filter_form.html.erb
    app/views/request/describe_notices/_error_message.html.erb
    app/views/request/describe_notices/_internal_review.html.erb
    app/views/request/describe_notices/_not_held.html.erb
    app/views/request/describe_notices/_successful.html.erb
    app/views/request/describe_notices/_waiting_response.html.erb
    app/views/request/describe_notices/_waiting_response_overdue.html.erb
    app/views/request/details.html.erb
    app/views/request/new.html.erb
    app/views/request/preview.html.erb
    app/views/request_mailer/stopped_responses.text.erb

# 0.28.0.10

## Highlighted Features

* Updated translations from Transifex (Gareth Rees)

# 0.28.0.9

## Highlighted Features

* Updated translations from Transifex (Liz Conlan)

# 0.28.0.8

## Highlighted Features

* Updated translations from Transifex (Liz Conlan)

# 0.28.0.7

## Highlighted Features

* Fix locale handling bug which prevented locales containing underscores from
  being used as an additional site language (Liz Conlan)

# 0.28.0.6

## Highlighted Features

* Break model constants containing translated text out into new methods in
  TranslatedConstants modules to prevent accidental caching of the default
  locale's translations (Liz Conlan, Gareth Rees)

## Upgrade Notes

* If you have overridden `LAW_USED_READABLE_DATA` in your theme, you will need
  to rewrite this code to override the `law_used_readable_data` class method of
  `InfoRequest::TranslatedConstants` instead

# 0.28.0.5

## Highlighted Features

* Fix bug in `Statistics.by_week_to_today_with_noughts` causing comparisons to
  fail (Gareth Rees)

# 0.28.0.4

## Highlighted Features

* Fix bug causing `MailServerLog#delivery_status` to return an ActiveRecord
  serialized attribute (Gareth Rees)

# 0.28.0.3

## Highlighted Features

* Updated translations from Transifex (Gareth Rees)

# 0.28.0.2

## Highlighted Features

* Fix indexing error when creating batch requests (Louise Crow)

## Upgrade Notes

There are some database structure updates so remember to rake db:migrate

# 0.28.0.1

## Highlighted Features

* Add config for `SECRET_KEY_BASE` (Gareth Rees).

## Upgrade Notes

* Rails 4.0 introduces ActiveSupport::KeyGenerator and uses this as a base from
  which to generate and verify signed cookies (among other things). Generate a
  secret with `bundle exec rake secret` and use this for the value of
  `SECRET_KEY_BASE` in `config/general.yml`.

# 0.28.0.0

## Highlighted Features

* Upgrade to Rails 4.0 (Gareth Rees, Louise Crow, Steve Day, Liz Conlan)
* The test-unit gem has been removed from the project's Gemfile.
  Alaveteli has used RSpec to run tests for a long time, but Test::Unit was
  also available. Due to an incompatibility between the two, and a desire to
  support a single environment, this is no longer the case.

## Upgrade Notes

* This release upgrades Alaveteli to use Rails 4.0. No public-facing API has
  been changed, but if you have custom theme code you may need to update it for
  Rails 4 compatibility. Follow instructions in the official Rails guide (
  http://guides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-3-2-to-rails-4-0-active-record)
  and review our commits in this release to investigate deprecation warnings.
* You may need to migrate any tests in your theme that were using Test::Unit
  to RSpec.

### Changed Templates

    app/views/admin_general/debug.html.erb
    app/views/admin_public_body_headings/_form.html.erb
    app/views/alaveteli_pro/info_requests/_sidebar.html.erb
    app/views/alaveteli_pro/info_requests/preview.html.erb
    app/views/comment/_comment_form.html.erb
    app/views/comment/preview.html.erb
    app/views/request/describe_state_message.html.erb
    app/views/request/preview.html.erb
    app/views/user/_signup.html.erb

# 0.27.1.2

# Highlighted Features

* Updated translations from Transifex (Gareth Rees)

# 0.27.1.1

# Highlighted Features

* Updated translations from Transifex (Liz Conlan)

# 0.27.1.0

## Highlighted Features

* Always send warnings of possible spam activity – configure blocking of spam
  activity with `ENABLE_ANTI_SPAM` (Gareth Rees)
* Fix downloading request Zips when they're unclassified (Gareth Rees)
* Handle parsing mail server logs when using a smarthost (Gareth Rees)
* Removed a reference to `MySociety::Config` (Caleb Tutty)
* Hide admin navigation items in request PDF download (Gareth Rees)
* Added a set of rake tasks to provide stats on user signups by email domain
  with the option to ban by domain if required (Liz Conlan)
* Added a data export task to help with research (Alex Parsons)
* Add slightly stricter constraints to InfoRequest summaries to prevent really
  short titles like "re" from being used while still allowing acronyms like
  RNIB through - only affects new requests, pre-existing requests which don't
  meet these new requirements will still be treated as valid (Liz Conlan)
* Make the "Show all attachments" and "Show fewer attachments" links on the
  request page translatable (Liz Conlan)

## Upgrade Notes

* The `:redact_idhash` option of `MailServerLog#line` has been replaced by the
  `:redact` option. It will be removed in release 0.29.

### Changed Templates

    app/views/comment/_single_comment.html.erb
    app/views/followups/preview.html.erb
    app/views/general/_log_in_bar.html.erb
    app/views/general/_nav_items.html.erb
    app/views/public_body/_search_ahead.html.erb
    app/views/request/_bubble.html.erb
    app/views/request/_incoming_correspondence.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/select_authority.html.erb
    app/views/user/bad_token.html.erb

# 0.27.0.9

## Highlighted Features

* Updated translations from Transifex (Gareth Rees)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.27.0.8

## Highlighted Features

* Updated translations from Transifex (Gareth Rees)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.27.0.7

## Highlighted Features

* Reverts changes in 0.27.0.6 (Louise Crow)

# 0.27.0.6

## Highlighted Features

* Incoming mails with large main body texts no longer raise error in calling
  code, just send exception notification (Louise Crow)

# 0.27.0.5

## Highlighted Features

* Updated translations from Transifex (Gareth Rees)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.27.0.4

## Highlighted Features

* Fix a bug that meant a Postgres collation that was not compatible with the
  local database encoding could be chosen (Liz Conlan)

# 0.27.0.3

## Highlighted Features
* Added some more documentation on the 0.27.0.0 release (Louise Crow)

# 0.27.0.2

## Highlighted Features
* Made `script/alert-expiring-embargoes` executable (Louise Crow)

# 0.27.0.1

## Highlighted Features
* Added some more documentation on the 0.27.0.0 release (Louise Crow)
* Fixed `rake temp:populate_request_due_dates` to not validate requests
  on saving, or try to populate fields that have already been populated
  (Louise Crow)
* Fixed a typo in the `delete-expired-embargoes` script

# 0.27.0.0

## Highlighted Features
* Time in application time zone is used where appropriate in code, this fixes
  a bug in due date calculation for zones offset from UTC (Louise Crow)
* Prevent long authority names overflowing on statistics page (Gareth Rees)
* Fix css bug which allowed some "visually-hidden" elements to affect page
  length (Liz Conlan)
* Header now contains pull-down menu for user-specific links, which has
  swapped place with the search box (Martin Wright)
* This release rolls out the first implementation of Alaveteli Pro - a service
  for use by journalists and campaigners. Includes ability to embargo requests,
  and dashboard for managing to-do items and requests. This is functionality
  being piloted in the UK and is not yet recommended for use in other locales
  (Steve Day, Martin Wright, Louise Crow)

## Upgrade Notes
* You can run this release without using the Alaveteli Pro functionality - by
  default it is switched off.
* Please update any overriden templates and theme code that reference times and
  dates to reference the local time zone where appropriate. e.g.

  Time.now => Time.zone.now
  Date.today => Date.current
  DateTime.parse => Time.zone.parse

  See https://robots.thoughtbot.com/its-about-time-zones for a description of
  how Rails handles time zones
* To store the significant dates for requests in the database, you must run
  `bundle exec rake temp:populate_request_due_dates` after deployment.
* To store events identifying at what point requests became overdue and very
  overdue, you must run `bundle exec rake temp:backload_overdue_info_request_events`
  and `bundle exec rake temp:backload_very_overdue_info_request_events`.
* This release contains some fairly extensive template changes, including the header
  change mentioned in Highlighted Features. If you're deploying in place (rather
  than using capistrano), you may find you need to run `bundle exec rake
  assets:clean`, `bundle exec rake
  assets:precompile` and restart your app server to fully flush cached old
  templates.
* There are some database structure updates so remember to `rake db:migrate`

### Changed Templates
    app/views/admin_holiday_imports/new.html.erb
    app/views/admin_public_body/edit.html.erb
    app/views/admin_request/edit.html.erb
    app/views/admin_request/show.html.erb
    app/views/comment/_single_comment.html.erb
    app/views/comment/_single_comment.text.erb
    app/views/comment/new.html.erb
    app/views/followups/_followup.html.erb
    app/views/followups/new.html.erb
    app/views/general/_advanced_search_tips.html.erb
    app/views/general/_frontpage_search_box.html.erb
    app/views/general/_responsive_header.html.erb
    app/views/general/_responsive_topnav.html.erb
    app/views/general/blog.html.erb
    app/views/general/search.html.erb
    app/views/info_request_batch/show.html.erb
    app/views/layouts/default.html.erb
    app/views/public_body/_body_listing_single.html.erb
    app/views/request/_after_actions.html.erb
    app/views/request/_bubble.html.erb
    app/views/request/_describe_state.html.erb
    app/views/request/_incoming_correspondence.html.erb
    app/views/request/_incoming_correspondence.text.erb
    app/views/request/_other_describe_state.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_outgoing_correspondence.text.erb
    app/views/request/_request_sent.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/_wall_listing.html.erb
    app/views/request/describe_notices/_successful.html.erb
    app/views/request/hidden.html.erb
    app/views/request/new.html.erb
    app/views/request/show.html.erb
    app/views/user/_user_listing_single.html.erb
    app/views/user/banned.html.erb
    app/views/user/rate_limited.html.erb
    app/views/user/show.html.erb
    app/views/widgets/show.html.erb
# 0.26.0.9

## Highlighted Features

* Fix a bug that meant a Postgres collation that was not compatible with the
  local database encoding could be chosen (Liz Conlan)

# 0.26.0.8

## Highlighted Features

* Updated translations from Transifex (Louise Crow)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.26.0.7

## Highlighted Features

* Fix a bug in the handling of incoming mail with no body, just
  attachments (Louise Crow)

# 0.26.0.6

## Highlighted Features

* Apply text masks and censor rules to attachments when downloading a whole
  request as a Zip file (Louise Crow, Gareth Rees)

## Upgrade Notes

* Check what information may have been released by auditing cached zip
  downloads:
  `bundle exec rake temp:audit_cached_zip_downloads_with_censor_rules`. Save
  this information somewhere to refer back to.
* Clear all cached Zip downloads so that masks and censor rules are applied the
  next time they are accessed:
  `bundle exec rake temp:remove_cached_zip_downloads`.

# 0.26.0.5

## Highlighted Features

* Added an instruction line to the translation source to warn against using
  double quotes for the email name translation string (Liz Conlan)
* Updated translations for Italy and Nepal (Liz Conlan)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.26.0.4

## Highlighted Features

* Updated translations for Italian locales (Liz Conlan)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.26.0.3

## Highlighted Features

* Updated translations for Italian translations to fix a bug that prevents
  mail sending from working properly if there are double quotes in the string
  used when constructing to email's to field (Liz Conlan)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.26.0.2

## Highlighted Features

* Updated translations (Liz Conlan)

## Upgrade Notes

* This hotfix just includes translation updates.

# 0.26.0.1

## Highlighted Features

* Minor tweaks to unify the action bars used on the authority and request pages
  (Martin Wright)
* Added the new action menu to the bottom of the correspondence thread after
  user feedback (Gareth Rees)

## Upgrade Notes

* This hotfix just makes a couple of template and style tweaks. You may need to
  update styles for the authority and request page action bars.

### Changed Templates

    app/views/admin_public_body/edit.html.erb
    app/views/widgets/show.html.erb

# 0.26.0.0

## Highlighted Features

* Moved user actions to an "action menu" on the request pages (Martin Wright,
  Gareth Rees, Liz Conlan)
* Added sorting to admin users list (Gareth Rees)
* Add `required` attribute to select authority form to prevent blank searches
  (Gareth Rees)
* Make spam term checking configurable (Gareth Rees)
* Exclude banned users from graphs and stats tasks (Liz Conlan)
* New statistics page that includes user stats to show top requesters and
  annotators, and hidden  requests. Includes a new event type of "hide" to
  make tracking and reporting on hidden requests much simpler. Need to run
  `rake temp:update_hide_event_type` to set up the data for this feature
  (Henare Degan, Luke Bacon)
* Added task to export last 2 days of requests (`cleanup:spam_requests`)
  (Gareth Rees)
* Added admin comments list page (Gareth Rees)
* Add "banned" label to banned users in admin users list for better visibility
  (Gareth Rees)
* Fix request counts for authorities on the body stats page (Henare Degan)
* Cached mail server log delivery status (Liz Conlan, Gareth Rees)
* Improved display of authority list in search results (Martin Wright)
* Added favicon to `admin`, `no_chrome` and attachment to html layouts
  (Gareth Rees)
* Search for requests made to a tagged set of public authorities (Henare Degan)
* Allow format to be parsed correctly so JSON searches work (Henare Degan)
* Improve styling of request status messages (Martin Wright)
* Stopped HTML Entities being included in emails (Liz Conlan)
* Added support for Ubuntu 14.04 LTS (Trusty Tahr) (Louise Crow)
* Stopped including the original mail in bounce messages to prevent us
  redistributing spam (Louise Crow)
* Added more modern request status icons from the default Alaveteli theme
  (Louise Crow)
* Made search interfaces more consistent (Martin Wright, Louise Crow)
* Added a package to automate updating the geoip databases (Henare Degan)
* New requests are now recorded as virtual pageviews in Google Analytics (Louise Crow)
* Fixed broken table cell markup (Luke Bacon)
* Added an admin link to outgoing correspondence (Gareth Rees)
* Fixed some minor bugs on the admin debug page (Henare Degan)
* Moved Javascript to end of body tag (Louse Crow)
* Improve Public Body import from CSV documentation and page layout (Liz Conlan,
  Gareth Rees)
* Apache and nginx example files now have far-future expiration dates for static assets
  to allow browser-based caching (Louise Crow)
* Improved design of request correspondence boxes (Martin Wright).
* Improved the listing of similar requests in the request page sidebar (Martin
  Wright)
* Added a "Make a Request" call to action to the sidebar of the request pages
  (Martin Wright)
* Fixed some missing markup on request description notices (Sam Smith)
* Improved wording of lists of requests requiring attention on the admin summary
  page (Louise Crow)
* Added strong parameters gem for better mass assignment security (Gareth Rees)
* Added experimental Xapian database replication (Hazel Smith, Louise Crow)
* Request prominence logic more consistent, embargoed requests introduced as an
  Alaveteli Pro feature (Louise Crow)


## Upgrade Notes

* To cache delivery status of existing mail server logs run
  `bundle exec rake temp:cache_delivery_status` after deployment.
* `InfoRequest.last_public_response_clause`,
  `InfoRequest.old_unclassified_params`,
  `InfoRequest.count_old_unclassified`,
  `InfoRequest.get_random_old_unclassified` and
  `InfoRequest.find_old_unclassified` have been removed. Use
  `InfoRequest.where_old_unclassified` and additional ARel query methods where
  necessary.
* You can improve the speed of your site by making sure that far-future expiration dates
  are being set on static assets - see the examples in the example config files (`config/
  httpd.conf-example` and `config/nginx.conf.example`).
* Install the `geoip-database-contrib` package to automatically fetch latest
  geoip databases.
* To make requests searchable based on their public body's tags you'll need to
  reindex Xapian. To make this quicker you can selectively reindex just the
  model and new term by running
  `bundle exec rake xapian:rebuild_index models="InfoRequestEvent" terms="X"`
* To update events to use the new 'hide' event type you need to run
  `rake temp:update_hide_event_type`
* If you've added Javascript to overriden view templates, you should wrap it
  in a `content_for :javascript` block. See http://api.rubyonrails.org/v3.2.22/classes/ActionView/Helpers/CaptureHelper.html#method-i-content_for
  for more information.
* If you've overridden models that use `attr_accessible` or `attr_protected`,
  you'll need to update them as per the [strong parameters migration guide]
  (https://github.com/rails/strong_parameters#migration-path-to-rails-4).
* There are some database structure updates so remember to `rake db:migrate`

### Changed Templates

    app/views/admin_general/_admin_navbar.html.erb
    app/views/admin_general/debug.html.erb
    app/views/admin_general/index.html.erb
    app/views/admin_public_body/edit.html.erb
    app/views/admin_public_body/import_csv.html.erb
    app/views/admin_public_body/new.html.erb
    app/views/admin_user/_user_table.html.erb
    app/views/admin_user/index.html.erb
    app/views/comment/_single_comment.html.erb
    app/views/contact_mailer/add_public_body.text.erb
    app/views/contact_mailer/to_admin_message.text.erb
    app/views/contact_mailer/update_public_body_email.text.erb
    app/views/contact_mailer/user_message.text.erb
    app/views/general/_advanced_search_tips.html.erb
    app/views/general/_footer.html.erb
    app/views/general/_frontpage_hero.html.erb
    app/views/general/_localised_datepicker.html.erb
    app/views/general/_new_request.html.erb
    app/views/general/_popup_banner.html.erb
    app/views/general/blog.html.erb
    app/views/general/search.html.erb
    app/views/info_request_batch_mailer/batch_sent.text.erb
    app/views/layouts/admin.html.erb
    app/views/layouts/default.html.erb
    app/views/layouts/no_chrome.html.erb
    app/views/outgoing_mailer/initial_request.text.erb
    app/views/public_body/_body_listing_single.html.erb
    app/views/public_body/_list_sidebar_extra.html.erb
    app/views/public_body/_search_ahead.html.erb
    app/views/public_body/statistics.html.erb
    app/views/public_body/view_email.html.erb
    app/views/public_body/view_email_captcha.html.erb
    app/views/request/_bubble.html.erb
    app/views/request/_incoming_correspondence.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_request_listing.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/_view_html_stylesheet.html.erb
    app/views/request/describe_notices/_requires_admin.html.erb
    app/views/request/new.html.erb
    app/views/request/select_authorities.html.erb
    app/views/request/select_authority.html.erb
    app/views/request/show.html.erb
    app/views/request_game/play.html.erb
    app/views/request_mailer/comment_on_alert.text.erb
    app/views/request_mailer/comment_on_alert_plural.text.erb
    app/views/request_mailer/new_response.text.erb
    app/views/request_mailer/new_response_reminder_alert.text.erb
    app/views/request_mailer/not_clarified_alert.text.erb
    app/views/request_mailer/old_unclassified_updated.text.erb
    app/views/request_mailer/overdue_alert.text.erb
    app/views/request_mailer/stopped_responses.text.erb
    app/views/request_mailer/very_overdue_alert.text.erb
    app/views/track_mailer/event_digest.text.erb
    app/views/user/set_crop_profile_photo.html.erb
    app/views/user_mailer/already_registered.text.erb
    app/views/user_mailer/changeemail_already_used.text.erb
    app/views/user_mailer/changeemail_confirm.text.erb
    app/views/user_mailer/confirm_login.text.erb

# Version 0.25.0.15

## Highlighted Features

* Added an IP rate limiter and rate limit signups to 3 per hour per IP if
  `ENABLE_ANTI_SPAM` is configured (Gareth Rees)
* Added a reCAPTCHA to the new request process for users who are not signed in,
  or have not been marked as `confirmed_not_spam`. This is controlled
  independently through `NEW_REQUEST_RECAPTCHA` (Louise Crow, Gareth Rees)
* Allow the additional anti-spam measures to be turned on and off by setting
  `ENABLE_ANTI_SPAM` (Louise Crow)
* Ability to block requests from country-based IP ranges. See
  `RESTRICTED_COUNTRIES` in `config/general.yml-example` for details
  (Louise Crow)
* Requests, about me text and comments are rejected if they match known spam
  patterns (Louise Crow)
* User-supplied links are now `rel=nofollow` (Louise Crow)
* Remove banned users from the search index to prevent them appearing in search
  results (Gareth Rees)

## Upgrade Notes

* Run `bundle exec rake cleanup:reindex_spam_users` to reindex banned users.

# Version 0.25.0.0

## Highlighted Features

* Compress all images to improve PageSpeed (Martin Wright)
* Prevent spam users using the "about me" page to propagate spam (Gareth Rees)
* Format incoming message HTML with `<p>` and `<br>` tags (Liz Conlan)
* Add an interface to calculate transaction stats per user (Gareth Rees)
* Fixed bug in `OutgoingMessage.template_changed` which allowed a new request to
  be submitted without changes to the default text if:
   - the site (theme) overrode the core default text via `default_letter`
   - the authority name contained any characters which were encoded as
     HTMLEntities
   - a global censor rule changed the template text
  Only the first case is known to affect a live site (Liz Conlan)
* There is now the ability to flag a request to have incoming mail rejected at
  SMTP time - requires special configuration at the MTA level. For more information on
  usage, see [the documentation on spam handling](http://alaveteli.org/docs/running/handling_spam/#advanced-feature---rejection-of-incoming-messages-at-the-mta) (Louise Crow)
* The raw email associated with an incoming message can now be downloaded from
  the admin page for that message without having to view the raw email first
  (Louise Crow)
* Improve sharing options on request sidebar (Gareth Rees, Martin Wright)
* Added a library to give a spam score to a user (Gareth Rees)
* Add ARIA landmark roles to improve accessibility (Martin Wright)
* Add an endpoint to view outgoing message mail server logs and display them
  in the request thread (Gareth Rees)
* Prevent the search and list routes from processing non-HTML requests
  (Liz Conlan)
* Add accepted formats to commonly probed routes (Gareth Rees)
* Added a helper and new lib file to standardise click tracking with Google
  Analytics events (Liz Conlan)
* Migrated from using the legacy `ga.js` Google Analytics code to the current
  "universal" `analytics.js` version (Liz Conlan)
* Bug fixes for the graph generation scripts (Liz Conlan)
* Improved DMARC handling (Louise Crow)
* Added a workaround for a compatibility issue with Xapian character encoding
  (Louise Crow)
* Minor accessibility improvements (Martin Wright)
* Add a task to output a CSV of the requests made to the top 20 authorities
  (Nick Jackson)
* Allow local code coverage to be generated by setting `COVERAGE=local` in the
  environment when running rspec (Liz Conlan)
* Refactored `OutgoingMailer` to get "To:", "From:" and "Subject:" from the
  `OutgoingMessage` instance (Gareth Rees)
* Show the delivery status of outgoing messages (Gareth Rees, Zarino Zappia)
* Added a rake task, `themes:check_help_sections` to identify missing help
  templates and sections in themes that are referred to in Alaveteli. Removed
  example help templates from core to `alavetelitheme`. (Louise Crow)
* Added a new config option `ENABLE_ANNOTATIONS` to allow turning off the
  annotations feature (comments on requests) (Steve Day, Gareth Rees)
* Added some early-stage scripts (`script/current-theme`,
  `script/diff-theme-override`) to help with upgrading theme overrides. Both
  have a `-h` option with usage information (Gareth Rees)
* Make it clearer that user's names will be displayed in public (Gareth Rees)
* The holding pen is now hidden by default in the front end interface (Louise Crow)

## Upgrade Notes

* `UserController#set_profile_about_me` has been deprecated. If you have
  overridden it in your theme, you will need to port your customisations to
  `UserProfile::AboutMeController`. You should also update
  `set_profile_about_me` routes to `edit_profile_about_me` (for GET requests)
  and `profile_about_me` (for PUT requests).
* `AboutMeValidator` has been deprecated. The behaviour is now directly included
  in `User`.
* Run `bundle exec rake themes:check_help_sections` to check that your theme
  contains all the necessary help files. The example files have now been moved
  from Alaveteli to the example theme `alavetelitheme`.
* The upgrade of Google Analytics affects any custom GA scripts embedded in
  template pages. You will need to go through your theme customisations to see
  whether or not you are affected. Changes include:
    * There is no longer a `pageTracker` object on the page, you must make your
      calls against `ga` instead
    * Core function calls like `_getTracker` and `_trackEvent` have been
      replaced by newer equivalents
    * The main method of tracking page views has changed from
      `pageTracker._trackPageView()` to `ga('send', 'pageview')`
    * The main method of sending tracking events has changed from
       `pageTracker._trackEvent(category, action)` to
       `ga('send', 'event', category, action)`
  Full information on how to check and adjust for these changes is available
  [in Google's migration guide](https://developers.google.com/analytics/devguides/collection/upgrade/#upgrade-guides)
* There are some database structure updates so remember to `rake db:migrate`
* This release includes an update to the commonlib submodule - you
  should be warned about this when running `rails-post-deploy`.

## Changed Templates

The following templates have been changed. Please update overrides in your theme
to match the new templates.

    app/views/admin_censor_rule/_show.html.erb
    app/views/admin_censor_rule/edit.html.erb
    app/views/admin_holidays/_edit_form.html.erb
    app/views/admin_incoming_message/_actions.html.erb
    app/views/admin_incoming_message/bulk_destroy.html.erb
    app/views/admin_outgoing_message/edit.html.erb
    app/views/admin_public_body_categories/edit.html.erb
    app/views/admin_public_body_headings/edit.html.erb
    app/views/admin_raw_email/show.html.erb
    app/views/admin_request/edit.html.erb
    app/views/admin_request/show.html.erb
    app/views/admin_spam_addresses/index.html.erb
    app/views/admin_track/_some_tracks.html.erb
    app/views/admin_user/_form.html.erb
    app/views/admin_user/show.html.erb
    app/views/comment/_single_comment.html.erb
    app/views/followups/_followup.html.erb
    app/views/followups/new.html.erb
    app/views/followups/preview.html.erb
    app/views/general/_advanced_search_tips.html.erb
    app/views/general/_footer.html.erb
    app/views/general/_frontpage_how_it_works.html.erb
    app/views/general/_frontpage_search_box.html.erb
    app/views/general/_header.html.erb
    app/views/general/_responsive_footer.html.erb
    app/views/general/_responsive_header.html.erb
    app/views/general/_responsive_topnav.html.erb
    app/views/general/_topnav.html.erb
    app/views/general/blog.html.erb
    app/views/general/exception_caught.html.erb
    app/views/general/search.html.erb
    app/views/help/_sidebar.html.erb
    app/views/help/_why_they_should_reply_by_email.html.erb
    app/views/help/about.html.erb
    app/views/help/alaveteli.html.erb
    app/views/help/api.html.erb
    app/views/help/contact.html.erb
    app/views/help/credits.html.erb
    app/views/help/officers.html.erb
    app/views/help/privacy.html.erb
    app/views/help/requesting.html.erb
    app/views/help/unhappy.html.erb
    app/views/info_request_batch/_batch_sent.html.erb
    app/views/layouts/default.html.erb
    app/views/one_time_passwords/show.html.erb
    app/views/public_body/_list_sidebar_extra.html.erb
    app/views/public_body/list.html.erb
    app/views/public_body/show.html.erb
    app/views/request/_act.html.erb
    app/views/request/_after_actions.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_request_sent.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/_wall_listing.html.erb
    app/views/request/describe_notices/_internal_review.html.erb
    app/views/request/describe_notices/_not_held.html.erb
    app/views/request/describe_notices/_successful.html.erb
    app/views/request/details.html.erb
    app/views/request/new.html.erb
    app/views/request/preview.html.erb
    app/views/request/select_authority.html.erb
    app/views/request/show.html.erb
    app/views/request_game/play.html.erb
    app/views/request_mailer/requires_admin.text.erb
    app/views/user/_show_user_info.html.erb
    app/views/user/_signup.html.erb
    app/views/user/_user_listing_single.html.erb
    app/views/user/banned.html.erb
    app/views/user/contact.html.erb
    app/views/user/no_cookies.html.erb
    app/views/user/river.html.erb
    app/views/user/set_draft_profile_photo.html.erb
    app/views/user/show.html.erb
    app/views/user/wall.html.erb
    app/views/widgets/show.html.erb

# Version 0.24.1.0

## Highlighted Features

 * Removed many cases of dynamic string composition, making Alaveteli easier to
   localise (Liz Conlan, Louise Crow).

## Upgrade Notes

 * Please update any overridden templates in the list below so that the phrases in
   them will be translated correctly.


### Changed Templates

The following templates have been changed. Please update overrides in your theme
to match the new templates.

    app/views/comment/_single_comment.html.erb
    app/views/comment/new.html.erb
    app/views/contact_mailer/to_admin_message.text.erb
    app/views/followups/new.html.erb
    app/views/public_body/_body_listing_single.html.erb
    app/views/public_body/view_email.html.erb
    app/views/request/new_bad_contact.html.erb
    app/views/request/show.html.erb
    app/views/request/similar.html.erb
    app/views/request/upload_response.html.erb
    app/views/request_mailer/requires_admin.text.erb
    app/views/user/show.html.erb
    app/views/user/sign.html.erb
    app/views/user/wrong_user_unknown_email.html.erb

# Version 0.24.0.0

## Highlighted Features

* Stopped enforcing line lengths in plain text emails for a better experience
  when using small screen clients such as mobile phones (Liz Conlan)
* Added Google Analytics tracking code to log an event when a widget button
  is clicked (Liz Conlan)
* Fix crash when neither Geoip nor Gaze are configured (Alfonso Cora)
* Added a system of checkboxes to allow admins to delete multiple incoming
  messages (ie spam) that are associated with a request (Liz Conlan)
* Added a new cron job to run the holding pen cleanup task once a week.
  (Liz Conlan)
* Improved the holiday reminder email that gets sent to site admins once a year
  (Liz Conlan)
* Extracted `ResponseController#show_response` in to several actions in a new
  `FollowupsController` (Liz Conlan, Gareth Rees)
* Added links to [AskTheEU](http://www.asktheeu.org) from Alaveteli sites
  installed in an EU country (Gareth Rees)
* Stopped generating code coverage reports locally. You can still view code
  coverage reports on https://coveralls.io/github/mysociety/alaveteli
  (Gareth Rees)
* Added `OutgoingMessage::Template` module and extracted templates to classes
  in this module (Gareth Rees)
* Added some experimental methods for sending requests to an external reviewer
  (Gareth Rees)
* Added some experimental methods for retrieving exim mail server logs for a
  specific `OutgoingMessage` (Gareth Rees)
* Improved the organisation of the items in the admin nav bar (Gareth Rees)
* Global and Public Body censor rules can now be managed through the admin UI
  (Gareth Rees)
* Added non-destructive methods to apply censor rules and text masks (Gareth
  Rees).
* Improve handling of long translations in logged in nav (Zarino Zappia)
* Better support for setting up a thin cluster (Liz Conlan)
* Added onscreen instructions to the Vagrant box (Liz Conlan)
* The UK-specific `SPECIAL_REPLY_VERY_LATE_AFTER_DAYS` has been removed. See
  https://github.com/mysociety/whatdotheyknow-theme/pull/287 for how we've
  re-implemented this in WhatDoTheyKnow.
* Stop outgoing messages being displayed with forced line breaks (Liz Conlan).
* Reduce risk of duplicate request urls (Liz Conlan).
* Better image for pages when shared on Facebook (Zarino Zappia)
* Official support added for ruby 2.1.5 and 2.3.0 (Louise Crow)
* Ported the graph generation shell scripts to Ruby (Liz Conlan)
* Official support added for Debian Jessie (Liz Conlan)
* Improved some translation strings and added some missing wrappers (Gareth
  Rees)
* Deprecated some UK-specific code (Gareth Rees)
* Improve speed of the 'old unclassified' requests query by adding a cached
  field to InfoRequest to keep track of when the last public response was
  made (Liz Conlan).
* Improved error messages in `script/switch-theme.rb` (Zarino Zappia)

## Upgrade Notes

* The following methods have been replaced:
  * `CensorRule#apply_to_text!`: `CensorRule#apply_to_text`
  * `CensorRule#apply_to_binary!`: `CensorRule#apply_to_binary`
  * `IncomingMessage#apply_masks!`: `IncomingMessage#apply_masks`
  * `InfoRequest#apply_censor_rules_to_text!`: `InfoRequest#apply_censor_rules_to_text`
  * `InfoRequest#apply_censor_rules_to_binary!`: `InfoRequest#apply_censor_rules_to_binary`
  * `AlaveteliTextMasker#apply_masks!`: `AlaveteliTextMasker#apply_masks`
  * `AlaveteliTextMasker#apply_pdf_masks!`: `AlaveteliTextMasker#apply_pdf_masks`
  * `AlaveteliTextMasker#apply_binary_masks!`: `AlaveteliTextMasker#apply_binary_masks`
  * `AlaveteliTextMasker#apply_text_masks!`: `AlaveteliTextMasker#apply_text_masks`

  Note that you will need to assign the return value from the new methods, e.g:

```diff
- censor_rule.apply_to_text!(text)
+ censored_text = censor_rule.apply_to_text(text)
```

* To switch to running multiple thin servers with nginx:
  * stop the running processes using `service alaveteli stop`
  * regenerate your SysVinit daemon file using the instructions at:
    [http://alaveteli.org/docs/installing/manual_install/#thin](http://alaveteli.org/docs/installing/manual_install/#thin) (but don't restart the site yet!)
  * Edit the upstream alaveteli directive in your `/etc/nginx/sites-available/alaveteli_https`
    (or `/etc/nginx/sites-available/alaveteli` if you are not running your site over SSL) file
    as per [http://alaveteli.org/docs/installing/manual_install/#running-over-ssl](http://alaveteli.org/docs/installing/manual_install/#running-over-ssl) so that nginx knows how to use
    the extra server processes
  * restart your site with `service alaveteli start`
* There's been a minor change to `config/sysvinit-passenger.example`. You should
  regenerate this file: http://alaveteli.org/docs/installing/manual_install/#passenger
* Add a 256x256 image named `logo-opengraph.png` to
  `YOUR_THEME_ROOT/assets/images`, to be shown next to pages from your site when
  shared on Facebook.
* The crontab needs to be regenerated to include the new modifications:
  http://alaveteli.org/docs/installing/manual_install/#generate-crontab
* 5af81d905 includes a migration that runs over all info requests in the
  database. This might take some time, so you should ideally **schedule this
  outside of busy periods**.

### Changed Templates

The following templates have been changed. Please update overrides in your theme
to match the new templates.

    app/views/admin_censor_rule/_form.html.erb
    app/views/admin_censor_rule/_show.html.erb
    app/views/admin_censor_rule/edit.html.erb
    app/views/admin_censor_rule/new.html.erb
    app/views/admin_general/_admin_navbar.html.erb
    app/views/admin_general/stats.html.erb
    app/views/admin_public_body/show.html.erb
    app/views/admin_request/show.html.erb
    app/views/comment/new.html.erb
    app/views/comment/preview.html.erb
    app/views/general/_responsive_footer.html.erb
    app/views/help/unhappy.html.erb
    app/views/info_request_batch/show.html.erb
    app/views/layouts/contact_mailer.text.erb
    app/views/layouts/default.html.erb
    app/views/layouts/outgoing_mailer.text.erb
    app/views/layouts/request_mailer.text.erb
    app/views/layouts/user_mailer.text.erb
    app/views/outgoing_mailer/_followup_footer.text.erb
    app/views/public_body/_body_listing_single.html.erb
    app/views/public_body/_list_sidebar_extra.html.erb
    app/views/public_body/list.html.erb
    app/views/public_body/show.html.erb
    app/views/public_body/statistics.html.erb
    app/views/public_body/view_email.html.erb
    app/views/public_body_change_requests/new.html.erb
    app/views/reports/new.html.erb
    app/views/request/_after_actions.html.erb
    app/views/request/_followup.html.erb
    app/views/request/_hidden_correspondence.html.erb
    app/views/request/_hidden_correspondence.text.erb
    app/views/request/_incoming_correspondence.html.erb
    app/views/request/_other_describe_state.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_request_sent.html.erb
    app/views/request/_restricted_correspondence.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/_sidebar_request_listing.html.erb
    app/views/request/batch_not_allowed.html.erb
    app/views/request/describe_state_message.html.erb
    app/views/request/details.html.erb
    app/views/request/followup_bad.html.erb
    app/views/request/followup_preview.html.erb
    app/views/request/hidden.html.erb
    app/views/request/new.html.erb
    app/views/request/preview.html.erb
    app/views/request/select_authority.html.erb
    app/views/request/show.html.erb
    app/views/request/show.text.erb
    app/views/request/show_response.html.erb
    app/views/request/similar.html.erb
    app/views/request/upload_response.html.erb
    app/views/request_mailer/overdue_alert.text.erb
    app/views/request_mailer/very_overdue_alert.text.erb
    app/views/track/_tracking_links.html.erb
    app/views/track_mailer/event_digest.text.erb
    app/views/user/_change_receive_email.html.erb
    app/views/user/_signin.html.erb
    app/views/user/_signup.html.erb
    app/views/user/_user_listing_single.html.erb
    app/views/user/rate_limited.html.erb
    app/views/user/set_profile_about_me.html.erb
    app/views/user/show.html.erb
    app/views/user/sign.html.erb
    app/views/user/signchangeemail.html.erb
    app/views/user/signchangepassword.html.erb
    app/views/user/signchangepassword_confirm.html.erb
    app/views/user/signchangepassword_send_confirm.html.erb
    app/views/user/wall.html.erb
    app/views/user/wrong_user.html.erb
    app/views/user_mailer/confirm_login.text.erb
    app/views/widgets/show.html.erb

# Version 0.23.2.0

## Highlighted Features

* Improve speed of the 'old unclassified' requests query by adding a cached
  field to InfoRequest to keep track of when the last public response was made (Liz Conlan).

## Upgrade Notes

* There are a couple of database structure updates so remember to rake db:migrate

# Version 0.23.1.0

## Highlighted Features

* Remove blocks of spaces in translation strings (Louise Crow).

## Upgrade Notes

* There should be no action necessary.

# Version 0.23

## Highlighted Features

* Various major design and markup improvements to the layout, home page and
  request page (Martin Wright).
* Adds basic opt-in two factor authentication. Enable it globally with
  `ENABLE_TWO_FACTOR_AUTH` (Gareth Rees).
* Fixes a bug which caused request titles to be HTML escaped twice
  when setting up a new request track while not logged in (Liz Conlan).
* Extracted UserController#signchangepassword to PasswordChangesController
  (Gareth Rees).
* Added configuration for `RESTRICT_NEW_RESPONSES_ON_OLD_REQUESTS_AFTER_MONTHS`.
  (Gareth Rees).
* Performance improvements when finding sibling info request events (Gareth
  Rees).
* Increased the maximum length of a track query and added a warning if
  this new limit is exceeded (Liz Conlan).
* Refactor of `InfoRequest` (Liz Conlan).
* Improved placeholder logo (Zarino Zappia).
* Improve mobile layout on authority list page (Martin Wright).
* Improve handling of associated records when destroying parents (Liz Conlan).
* Major refactoring of `InfoRequest#receive` (Gareth Rees).
* Santitze invalid UTF-8 in mail server logs while processing them (Steven Day,
  Gareth Rees).
* Fixes for several edge case bugs (Liz Conlan).
* Add more classes to markup to make style customisation easier (Martin Wright).
* Adds reCAPTCHA to the public authority change request form if there is no
  logged in user (Gareth Rees).
* Rename #follow_box to #track-request to prevent add blockers hiding the
  button allowing users to follow a request (Martin Wright).
* Improved handling of invalid UTF-8 attachment text (Louise Crow).
* Add domain to exception notification subject line (Gareth Rees).
* Fixes incorrectly updating `url_name` when a banned user record is updated
  (Gareth Rees).
* Definition lists are now easier to read and follow, greatly improves help
  pages (Martin Wright).
* The sorting on PublicBodyController#list now uses `COLLATE` to sort in the
  correct order for a locale if a collation is available for the language. See
  http://alaveteli.org/docs/developers/i18n/#internationalised-sorting for
  adding collations. This requires PostgreSQL >= 9.1.12. (Gareth Rees)
* The new widget template can now be translated (Gareth Rees).
* Improved locale switcher markup and code (Martin Wright, Gareth Rees).
* OpenGraph markup added to improve the appearance of Alaveteli links on social
  media (Owen Blacker).
* Request graph cron job no longer errors if there are no requests in a
  particular state (Petter Reinholdtsen).
* Refactoring of user controller for shorter methods and clearer syntax (Caleb
  Tutty)
* New rake task stats:list_hidden for printing a list of requests with hidden
  material (Louise Crow).
* Rspec is upgraded to version 3, and specs have been upgraded to modern
  syntax (Louise Crow).
* Standard filters and parameter whitelisting added to admin controllers
  (James McKinney, Louise Crow)
* Alaveteli now uses a local GeoIP database by default to find the country for
  HTTP requests (and tell users if there is an Alaveteli in their country),
  rather than the mySociety Gaze service. This should improve performance and
  reliability (Ian Chard).
* The 'Return-Path' header for mails from users is now set to an email address on
  the Alaveteli domain so that SPF checks should pass (Louise Crow).
* **Debian Squeeze is no longer supported as an OS to run Alaveteli on.** It is
  end-of-life in Feb 2016 and only packages Ruby 1.8.

## Upgrade Notes

* **Version 0.23 does not support Ruby 1.8.7.**

* If you are running Alaveteli on Debian Squeeze, you should upgrade your OS to
  Debian Wheezy before upgrading to this release. This
  [Debian upgrade guide](https://www.debian.org/releases/oldstable/amd64/release-notes/ch-upgrading)
  can guide you through the process. If you have
  questions about upgrading OS, please don't hesitate to ask on the
  [alaveteli-dev](https://groups.google.com/forum/#!forum/alaveteli-dev) group.
  If you're not ready to upgrade to Wheezy, you can still upgrade Alaveteli if
  you install Ruby 1.9 or 2.0 yourself, but be aware that we will no longer be
  testing package installation on Squeeze and that OS security updates will no
  longer be produced by Debian after Feb 2016.
* The install script `site-specific-install.sh` sets the default ruby to 1.9. You
  can do this manually with the same commands http://git.io/vlDpb
* If you are running Debian Wheezy, install poppler-utils from wheezy-backports:
  http://git.io/vlD1k
* This release adds `geoip-database` to the list of required packages. You can
  install it with `sudo apt-get install geoip-database`. If you don't want to
  or can't use a local GeoIP database, set `GEOIP_DATABASE' to an empty string in
  `config/general.yml`.
* Make sure that your 'blackhole email address' is configured to be
  discarded by your MTA - see our [postfix](
  http://alaveteli.org/docs/installing/email/#discard-unwanted-incoming-email)
  and [exim](http://alaveteli.org/docs/installing/email/#discard-unwanted-incoming-email-1)
  setup documentation.
* This release introduces a new default homepage - if you want to keep your existing
  homepage layout, copy the old homepage templates to your theme before upgrading and
  check that you have translations for them in your `theme-locale` directory.
* `UserController#signchangepassword` has been deprecated and password changing
  moved to a separate controller, `PasswordChangesController`. If you still need
  the old action, add the following route to your theme's
  `lib/config/custom_routes.rb`:

    match '/profile/change_password' => 'user#signchangepassword',
          :as => :signchangepassword

  If you do this, you'll also need to change any url helpers from `new_password_change_path`
  to `signchangepassword_path`.
* This release takes the first steps to deprecate the `link_button_green` class, which
  will be removed in a future release. We've added contextually relevant
  classes to these elements. Please update your themes to ensure you're
  no longer using `link_button_green` for styling.
* The `InfoRequest` methods `law_used_short`, `law_used_act` and `law_used_with_a`
  have been deprecated and will be removed in a future release. The new method
  `law_used_human` has been supplied instead which takes a key to access the
  equivalent information of the original methods, e.g. `law_used_human(:full)`,
  `law_used_human(:short)` etc. As the `law_used_with_a` functionality does not
  appear to be in use, if you do still need this functionality in future you
  may need to override the `LAW_USED_READABLE_DATA` hash to ensure it has a
  `:with_a` key value pair for each law you are supporting before calling
  `law_used_human(:with_a)`.
* Please upgrade the syntax in any theme specs you have to be compatible with
  rspec 3. Useful resources:
  * https://relishapp.com/rspec/docs/upgrade
  * http://yujinakayama.me/transpec/
* There are a couple of database structure updates so remember to `rake db:migrate`
* This release includes an update to the commonlib submodule - you
  should be warned about this when running rails-post-deploy.


### Changed Templates

The following templates have been changed. Please update overrides in your theme
to match the new templates.


    app/views/admin_public_body/_locale_fields.html.erb
    app/views/admin_public_body/edit.html.erb
    app/views/admin_public_body_categories/_form.html.erb
    app/views/admin_public_body_categories/_locale_fields.html.erb
    app/views/admin_public_body_categories/edit.html.erb
    app/views/admin_public_body_categories/new.html.erb
    app/views/admin_public_body_headings/_form.html.erb
    app/views/admin_public_body_headings/_locale_fields.html.erb
    app/views/admin_public_body_headings/edit.html.erb
    app/views/admin_public_body_headings/new.html.erb
    app/views/admin_request/edit.html.erb
    app/views/admin_request/show.html.erb
    app/views/general/_advanced_search_tips.html.erb
    app/views/general/_footer.html.erb
    app/views/general/_frontpage_bodies_list.html.erb
    app/views/general/_frontpage_intro_sentence.html.erb
    app/views/general/_frontpage_new_request.html.erb
    app/views/general/_frontpage_requests_list.html.erb
    app/views/general/_frontpage_search_box.html.erb
    app/views/general/_header.html.erb
    app/views/general/_locale_switcher.html.erb
    app/views/general/_responsive_credits.html.erb
    app/views/general/_responsive_footer.html.erb
    app/views/general/_responsive_header.html.erb
    app/views/general/_responsive_topnav.html.erb
    app/views/general/_topnav.html.erb
    app/views/general/blog.html.erb
    app/views/general/exception_caught.html.erb
    app/views/general/frontpage.html.erb
    app/views/general/search.html.erb
    app/views/help/_sidebar.html.erb
    app/views/help/about.html.erb
    app/views/help/alaveteli.html.erb
    app/views/help/api.html.erb
    app/views/help/contact.html.erb
    app/views/help/credits.html.erb
    app/views/help/officers.html.erb
    app/views/help/privacy.html.erb
    app/views/help/requesting.html.erb
    app/views/help/unhappy.html.erb
    app/views/info_request_batch/_batch_sent.html.erb
    app/views/layouts/default.html.erb
    app/views/outgoing_mailer/initial_request.text.erb
    app/views/public_body/_body_listing_single.html.erb
    app/views/public_body/list.html.erb
    app/views/public_body/show.html.erb
    app/views/public_body/statistics.html.erb
    app/views/public_body/view_email.html.erb
    app/views/public_body_change_requests/new.html.erb
    app/views/request/_act.html.erb
    app/views/request/_after_actions.html.erb
    app/views/request/_followup.html.erb
    app/views/request/_hidden_correspondence.html.erb
    app/views/request/_request_search_form.html.erb
    app/views/request/_request_sent.html.erb
    app/views/request/_restricted_correspondence.html.erb
    app/views/request/_search_ahead.html.erb
    app/views/request/_sidebar.html.erb
    app/views/request/followup_bad.html.erb
    app/views/request/followup_preview.html.erb
    app/views/request/list.html.erb
    app/views/request/new.html.erb
    app/views/request/new_bad_contact.html.erb
    app/views/request/preview.html.erb
    app/views/request/select_authorities.html.erb
    app/views/request/select_authority.html.erb
    app/views/request/show.html.erb
    app/views/request/show_response.html.erb
    app/views/request_game/play.html.erb
    app/views/request_mailer/comment_on_alert.text.erb
    app/views/request_mailer/comment_on_alert_plural.text.erb
    app/views/request_mailer/new_response.text.erb
    app/views/request_mailer/not_clarified_alert.text.erb
    app/views/request_mailer/old_unclassified_updated.text.erb
    app/views/request_mailer/overdue_alert.text.erb
    app/views/request_mailer/requires_admin.text.erb
    app/views/request_mailer/stopped_responses.text.erb
    app/views/request_mailer/very_overdue_alert.text.erb
    app/views/track/_tracking_links.html.erb
    app/views/user/_show_user_info.html.erb
    app/views/user/_signin.html.erb
    app/views/user/_signup.html.erb
    app/views/user/set_crop_profile_photo.html.erb
    app/views/user/set_draft_profile_photo.html.erb
    app/views/user/show.html.erb
    app/views/user/sign.html.erb
    app/views/user/signchangeemail.html.erb
    app/views/user/signchangepassword.html.erb
    app/views/user/signchangepassword_send_confirm.html.erb
    app/views/user/signin_successful.html.erb
    app/views/user/wall.html.erb
    app/views/user/wrong_user.html.erb
    app/views/user/wrong_user_unknown_email.html.erb
    app/views/widgets/new.html.erb

# Version 0.22.4.0

## Highlighted Features

* Set the return-path for the contact form mail (Louise Crow).

## Upgrade Notes

* There should be no action necessary.

# Version 0.22.3.0

## Highlighted Features

* Added additional transaction stats to /version.json endpoint (Gareth Rees).
* Added additional transaction stats to stats:show rake task (Gareth Rees).

## Upgrade Notes

* There should be no action necessary.

# Version 0.22.2.0

## Highlighted Features

* Adds filtering of incoming mail based on a spam score from SpamAssassin.
  Requests over a threshold can be discarded or sent to the holding pen.
  See http://alaveteli.org/docs/customising/config#incoming_email_spam_action
  for configuration instructions (Gareth Rees).

## Upgrade Notes

* There should be no action necessary.

# Version 0.22.1.0

## Highlighted Features

* The source code now uses two-space indentation (Gareth Rees).
* A `FACEBOOK_USERNAME` configuration option is now available (Gareth Rees).
* The [`json` API for public bodies](http://alaveteli.org/docs/developers/api/#json-structured-data)
  now includes statistics on the number of requests, number of visible successful classified requests,
  and number of successful, overdue, not held requests (Ross Jones).

## Upgrade Notes

* There should be no action necessary.
* Most templates have changed to two-space indentation. For ease of future
  upgrades you _should_ update your overrides to match.

# Version 0.22

## Highlighted Features

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
* Remove dependency on tools provided by sharutils package (Gareth Rees).
* Use rack-utf8_sanitizer to handle badly-formed UTF-8 in request URI and
  headers (Louise Crow).
* Correctly handle names with commas in ContactMailer (Louise Crow).
* Various performance improvements in InfoRequestEvent (Gareth Rees).
* Improve performance of PublicBodyController#show (Gareth Rees).
* Various performance improvements in PublicBody (Gareth Rees).
* General improvements to string encoding handling (Louise Crow).
* Allow locale specific language names (Louise Crow).
* Fix count of requests on authority page (Henare Degan).
* Added Croatian Alaveteli to the list of world FOI websites
  (Miroslav Schlossberg).
* Various code duplication cleanup (James McKinney).
* Improve error reporting on graph generation (Petter Reinholdtsen).
* Admin summary page performance improvements (Gareth Rees).
* Various performance improvements in InfoRequest (Gareth Rees).
* Add missing ttf-bitstream-vera package (Petter Reinholdtsen).
* Send mail import errors to exception notification address (Louise Crow).
* Add bullet for tracking N+1 queries in development environment. Turn on by
  setting `USE_BULLET_IN_DEVELOPMENT` to `true` (Gareth Rees).
* Performance improvement when initializing InfoRequest instances (Gareth Rees).
* root no longer required to read mail logs
* Code quality improvements to ActsAsXapian (Louise Crow).
* Don't put HTML entities in email subject lines (Henare Degan).
* Defunct authorities are removed from the list of authorities with mising
  emails on the admin summary page (Henare Degan).
* Correctly encode words to highlight (Caleb Tutty).
* The request email of a PublicBody with a blank request_email database
  attribute will not be overridden by `OVERRIDE_ALL_PUBLIC_BODY_REQUEST_EMAILS`
  (Henare Degan).
* Fixed a bug in the HealthChecksHelper when applying 'OK' style (Caleb Tutty).
* Keep cookies from txt files in suggested Varnish configuration (Henare Degan).
* Improvements to the Categorisation Game charts (Henare Degan).
* Destroing an InfoRequest now destroys associated Comments and CensorRules
  (Louise Crow).
* There is experimental support for using an STMP server, rather than sendmail,
  for outgoing mail. There is not yet any ability to retry if the SMTP server is
  unavailable (Caleb Tutty, Louise Crow).
* HTML 'widgets' advertising requests can be displayed on other sites in iframes.
  If `ENABLE_WIDGETS` is set to true in `general.yml` (the default is false), a link
  to the widget code will appear in the right hand sidebar of a request page.
  (Jody McIntyre, Louise Crow).
* Capistrano now caches themes (Henare Degan).
* Improve correspondence box padding (Luke Bacon).
* Improve empty PublicBody translation rejection (Henare Degan).
* New message attachment icons (Martin Wright).
* Improve localisation (Louise Crow, Petter Reinholdtsen, Gorm Eriksen).
* Update xapian-full-alaveteli for Ruby 2.1 compatibility (Louise Crow).
* Improve header search form (Luke Bacon).
* Fix 'link to this' button on touch devices (Luke Bacon).

## Upgrade Notes

* **Version 0.22 is the last release to support Ruby 1.8.7.**

  We have an evolving [upgrade guide](http://git.io/vLNg0) on the wiki, and
  we're always available on the [alaveteli-dev mailing list](https://goo.gl/6u67Jg).
* Ruby version files are ignored – these are delegated to people's development
  or deployment environments. See https://goo.gl/01MCCi and e5180fa89.
* Ensure all overridden Ruby source files have encoding specifier. See
  576b58803.
* Memcached namespace is now dependent on Ruby version. No action required.
* Capistrano now caches themes in `shared/themes`. Run the `deploy:setup` task
  to create the shared directory before making a new code deploy.
* Example daemon files have been renamed (7af5e9d). You'll need to use the new
  names in any scripts or documentation you've written.
* Regenerate alert tracks and purge varnish daemons to get better stop daemon
  handling.
* Regenerate Varnish config so that cookies from txt files are not ignored.
  See db2db066.
* Regenerate the crontab so that root is no longer used to read mail logs.
* Give the unix application user membership of the adm group so that they can
  read the mail log files `usermod -a -G adm "$UNIX_USER"`
* Remove summary stats from admin summary page. They're duplicated on
  /admin/summary. No action required.
* The default branch has been changed from `rails-3-develop` to `develop`. Use
  of `rails-3-develop` will stop, and the branch will be removed at some point.
* Add the ttf-bitstream-vera package to provide Vera.ttf to the cron jobs.
* Alaveteli no longer requires the sharutils package.
* Remember to `rake db:migrate` and `git submodule update`
* If you handle attachment text in your theme, note that:
    * `FoiAttachment#body` will always return a binary encoded string
    * `FoiAttachment#body_as_text` will always return a UTF-8 encoded string
    * `FoiAttachment#default_body` will return a UTF-8 encoded string for text
      content types, and a binary encoded string for all other types.

### Changed Templates

The following templates have been changed. Please update overrides in your theme
to match the new templates.

    app/views/admin_general/index.html.erb
    app/views/admin_public_body/edit.html.erb
    app/views/comment/_comment_form.html.erb
    app/views/comment/_single_comment.html.erb
    app/views/general/_responsive_topnav.html.erb
    app/views/help/unhappy.html.erb
    app/views/public_body/show.html.erb
    app/views/public_body_change_requests/new.html.erb
    app/views/request/_act.html.erb
    app/views/request/_followup.html.erb
    app/views/request/_incoming_correspondence.html.erb
    app/views/request/_outgoing_correspondence.html.erb
    app/views/request/_request_listing_via_event.html.erb
    app/views/request/_request_search_form.html.erb
    app/views/request/_resent_outgoing_correspondence.html.erb
    app/views/request/new.html.erb
    app/views/request/new_bad_contact.html.erb
    app/views/request/show.html.erb
    app/views/request_game/play.html.erb
    app/views/track/_tracking_links.html.erb
    app/views/user/_user_listing_single.html.erb
    app/views/user/show.html.erb

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
