require 'simplecov'
require 'simplecov-lcov'

if ENV['COVERAGE'] == 'local'
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter

else
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
end

SimpleCov.start('rails') do
  add_filter  'commonlib'
  add_filter  'vendor/plugins'
  add_filter  'lib/attachment_to_html'
  add_filter  'lib/has_tag_string'
  add_filter  'lib/acts_as_xapian'
  add_filter  'lib/themes'
  add_filter  '.bundle'
end
