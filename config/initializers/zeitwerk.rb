Rails.autoloaders.main.inflector.inflect(
  "alaveteli_geoip" => "AlaveteliGeoIP",
  "alaveteli_gettext" => "AlaveteliGetText",
  "ip_rate_limiter" => "IPRateLimiter",
  "pstore_database" => "PStoreDatabase",
  "public_body_csv" => "PublicBodyCSV",
  "world_foi_websites" => "WorldFOIWebsites"
)

# search.rb reopens the Search module (adding facade methods) rather than
# defining Search::Search, so Zeitwerk must ignore it. It is required below
# after the ignore list.
Rails.autoloaders.main.ignore("#{Rails.root}/app/search/search.rb")
require_relative "../../app/search/search"

Rails.autoloaders.main.ignore(
  "lib/configuration.rb",
  "lib/i18n_fixes.rb",
  "lib/languages.rb",
  "lib/mail_handler/backends/mail_extensions.rb",
  "lib/no_constraint_disabling.rb",
  "lib/normalize_string.rb",
  "lib/quiet_opener.rb",
  "lib/routing_filters.rb",
  "lib/stripe_mock_patch.rb",
  "lib/theme.rb",
  "lib/use_spans_for_errors.rb"
)
