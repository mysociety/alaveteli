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
  skip 'commonlib'
  skip 'vendor/plugins'
  skip 'lib/attachment_to_html'
  skip 'lib/has_tag_string'
  skip 'lib/acts_as_xapian'
  skip 'lib/themes'
  skip '.bundle'
end
