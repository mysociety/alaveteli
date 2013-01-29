# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # The order (!) of this is important thanks to foreign keys
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

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #config.order = "random"

  # This is a workaround for a strange thing where ActionMailer::Base.deliveries isn't being
  # cleared out correctly in controller specs. So, do it here for everything.
  config.before(:each) do
    ActionMailer::Base.deliveries = []
  end

end

# XXX No idea what namespace/class/module to put this in
# Create a clean xapian index based on the fixture files and the raw_email data.
def create_fixtures_xapian_index
    load_raw_emails_data
    rebuild_xapian_index
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

def load_test_categories
    PublicBodyCategories.add(:en, [
        "Local and regional",
            [ "local_council", "Local councils", "a local council" ],
        "Miscellaneous",
            [ "other", "Miscellaneous", "miscellaneous" ],])
end

def basic_auth_login(request, username = nil, password = nil)
    username = Configuration::admin_username if username.nil?
    password = Configuration::admin_password if password.nil?
    request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{username}:#{password}")
end

