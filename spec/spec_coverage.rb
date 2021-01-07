require 'simplecov'
require 'coveralls'

cov_formats = [Coveralls::SimpleCov::Formatter]
cov_formats << SimpleCov::Formatter::HTMLFormatter if ENV['COVERAGE'] == 'local'

# Generate coverage in coveralls.io and locally if requested
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [*cov_formats]
)

SimpleCov.start('rails') do
  add_filter  'commonlib'
  add_filter  'vendor/plugins'
  add_filter  'lib/attachment_to_html'
  add_filter  'lib/has_tag_string'
  add_filter  'lib/acts_as_xapian'
  add_filter  'lib/themes'
  add_filter  '.bundle'
end
