require 'simplecov'
require 'coveralls'

# Generate coverage locally in html as well as in coveralls.io
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start('rails') do
  add_filter  'commonlib'
  add_filter  'vendor/plugins'
end

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = 'test'
require File.expand_path(File.join('..', '..', 'config', 'environment'), __FILE__)
require 'spec/autorun'
require 'spec/rails'

# set a default username and password so we can test
config = MySociety::Config.load_default()
config['ADMIN_USERNAME'] = 'foo'
config['ADMIN_PASSWORD'] = 'baz'

# tests assume 20 days
config['REPLY_LATE_AFTER_DAYS'] = 20

# register a fake Varnish server
require 'fakeweb'
FakeWeb.register_uri(:purge, %r|varnish.localdomain|, :body => "OK")

Webrat.configure do |config|
    config.mode = :rails
end

# Use test-specific translations
FastGettext.add_text_domain 'app', :path => File.join(File.dirname(__FILE__), 'fixtures', 'locale'), :type => :po
FastGettext.default_text_domain = 'app'
Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb

  # fixture_path must end in a separator
  config.fixture_path = File.join(Rails.root, 'spec', 'fixtures') + File::SEPARATOR
  config.global_fixtures = :users,
                           :public_bodies,
                           :public_body_translations,
                           :public_body_versions,
                           :info_requests,
                           :raw_emails,
                           :incoming_messages,
                           :outgoing_messages,
                           :comments,
                           :info_request_events,
                           :track_things,
                           :foi_attachments,
                           :has_tag_string_tags,
                           :holidays,
                           :track_things_sent_emails

  # This section makes the garbage collector run less often to speed up tests
  last_gc_run = Time.now

  config.before(:each) do
    GC.disable
  end

  config.after(:each) do
    if Time.now - last_gc_run > 4
      GC.enable
      GC.start
      last_gc_run = Time.now
    end
  end

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = Rails.root + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses its own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
end

# XXX No idea what namespace/class/module to put this in
def receive_incoming_mail(email_name, email_to, email_from = 'geraldinequango@localhost')
    email_name = file_fixture_name(email_name)
    content = File.read(email_name)
    content.gsub!('EMAIL_TO', email_to)
    content.gsub!('EMAIL_FROM', email_from)
    RequestMailer.receive(content)
end

def file_fixture_name(file_name)
    return File.join(Spec::Runner.configuration.fixture_path, "files", file_name)
end

def load_file_fixture(file_name, as_binary=false)
    file_name = file_fixture_name(file_name)
    content = File.open(file_name, 'r') do |file|
        if as_binary
            file.set_encoding(Encoding::BINARY) if file.respond_to?(:set_encoding)
        end
        file.read
    end
    return content
end

def parse_all_incoming_messages
    IncomingMessage.find(:all).each{ |x| x.parse_raw_email! }
end

def load_raw_emails_data
    raw_emails_yml = File.join(Spec::Runner.configuration.fixture_path, "raw_emails.yml")
    for raw_email_id in YAML::load_file(raw_emails_yml).map{|k,v| v["id"]} do
        raw_email = RawEmail.find(raw_email_id)
        raw_email.data = load_file_fixture("raw_emails/%d.email" % [raw_email_id])
    end
end

# Rebuild the current xapian index
def rebuild_xapian_index(terms = true, values = true, texts = true, dropfirst = true)
    if dropfirst
        begin
            ActsAsXapian.readable_init
            FileUtils.rm_r(ActsAsXapian.db_path)
        rescue RuntimeError
        end
        ActsAsXapian.writable_init
        ActsAsXapian.writable_db.close
    end
    parse_all_incoming_messages
    # safe_rebuild=true, which involves forking to avoid memory leaks, doesn't work well with rspec.
    # unsafe is significantly faster, and we can afford possible memory leaks while testing.
    models = [PublicBody, User, InfoRequestEvent]
    ActsAsXapian.rebuild_index(models, verbose=false, terms, values, texts, safe_rebuild=false)
end

# Create a clean xapian index based on the fixture files and the raw_email data.
def create_fixtures_xapian_index
    load_raw_emails_data
    rebuild_xapian_index
end

def update_xapian_index
    ActsAsXapian.update_index(flush_to_disk=false, verbose=false)
end

# Copy the xapian index created in create_fixtures_xapian_index to a temporary
# copy at the same level and point xapian at the copy
def get_fixtures_xapian_index()
    # Create a base index for the fixtures if not already created
    $existing_xapian_db ||= create_fixtures_xapian_index
    # Store whatever the xapian db path is originally
    $original_xapian_path ||= ActsAsXapian.db_path
    path_array = $original_xapian_path.split(File::Separator)
    path_array.pop
    temp_path = File.join(path_array, 'test.temp')
    FileUtils.remove_entry_secure(temp_path, force=true)
    FileUtils.cp_r($original_xapian_path, temp_path)
    ActsAsXapian.db_path = temp_path
end

def basic_auth_login(request, username = nil, password = nil)
    username = Configuration::admin_username if username.nil?
    password = Configuration::admin_password if password.nil?
    request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{username}:#{password}")
end

# to_ary differs in Ruby 1.8 and 1.9
# @see http://yehudakatz.com/2010/01/02/the-craziest-fing-bug-ive-ever-seen/
def safe_mock_model(model, args = {})
  mock = mock_model(model, args)
  mock.should_receive(:to_ary).any_number_of_times
  mock
end

def get_fixture_mail(filename)
    MailHandler.mail_from_raw_email(load_file_fixture(filename))
end

def load_test_categories
    PublicBodyCategories.add(:en, [
        "Local and regional",
            [ "local_council", "Local councils", "a local council" ],
        "Miscellaneous",
            [ "other", "Miscellaneous", "miscellaneous" ],])
end


# Monkeypatch applicationcontroller because the `render_to_string`
# method in the original breaks all the rspec test assertions such as
# `should render_template('foo')`.  Same problem as
# http://stackoverflow.com/questions/8174415/is-it-possible-to-assert-template-or-render-template-against-the-same-partial-wi
# - a bug in either Rails or Rspec I don't have the time to fix :(

class ApplicationController < ActionController::Base
    def set_popup_banner
        @popup_banner = nil
    end
end


def with_env_tz(new_tz = 'US/Eastern')
  old_tz, ENV['TZ'] = ENV['TZ'], new_tz
  yield
ensure
  old_tz ? ENV['TZ'] = old_tz : ENV.delete('TZ')
end

def with_active_record_default_timezone(zone)
  old_zone, ActiveRecord::Base.default_timezone = ActiveRecord::Base.default_timezone, zone
  yield
ensure
  ActiveRecord::Base.default_timezone = old_zone
end
