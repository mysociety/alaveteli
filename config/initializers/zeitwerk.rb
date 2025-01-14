Rails.autoloaders.main.inflector.inflect(
  "alaveteli_geoip" => "AlaveteliGeoIP",
  "alaveteli_gettext" => "AlaveteliGetText",
  "html_to_pdf_converter" => "HTMLtoPDFConverter",
  "ip_rate_limiter" => "IPRateLimiter",
  "pstore_database" => "PStoreDatabase",
  "public_body_csv" => "PublicBodyCSV",
  "world_foi_websites" => "WorldFOIWebsites"
)

Rails.autoloaders.main.ignore(
  "lib/confidence_intervals.rb",
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
