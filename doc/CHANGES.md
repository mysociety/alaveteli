# Version 0.5

## Highlighted features
* It should now be possible to develop the software on OSX 
* Base design refactored: CSS simplified and reduced, base design colours removed, now provided in example Alaveteli theme override

## Upgrade notes
* Themes created for 0.4 and below will need to be changed to match the new format.  
  * You should create a resources folder at `<yourtheme>/public/` and symlink to it from the main rails app.  See the `install.rb` in `alaveteli-theme` example theme for details.
  * Your styles should be moved from `general/custom_styles.rhtml` to a standalone stylesheet in `<yourtheme>/public/stylesheets/`
  * The partial at `general/_before_head_end.rhtml` should be changed in the theme to include this stylesheet


# Version 0.4

## Highlighted features
* Complete overhaul of design, including improved search, modern look and feel, more twitter links, etc
* A banner alerts visitors from other countries to existing sites in their country, or exhorts them to make their own
* Bounce emails that result from user alerts are automatically processed and hard bouncing accounts do not continue to receive alerts.
  See the new instructions in INSTALL-exim4.md for details of how to set this up.
* Logged in users now have the ability to download a zipfile of the entire correspondence for a request
* Improved UI for responding to requests.  The user now has a single option to "reply" at the bottom of a request, and can adjust who they are replying to on the next page
* [Full list of changes on github](https://github.com/sebbacon/alaveteli/issues?sort=created&direction=desc&state=closed&milestone=7)

## Upgrade notes
* Remember to `rake db:migrate` and `git submodule update`
* Ensure you have values for new config variables (see `config/general.yml-example`):
  * FORWARD_NONBOUNCE_RESPONSES_TO
  * TRACK_SENDER_EMAIL
  * TRACK_SENDER_NAME
  * HTML_TO_PDF_COMMAND
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
* [Full list of changes on github](https://github.com/sebbacon/alaveteli/issues?milestone=5&state=closed)
