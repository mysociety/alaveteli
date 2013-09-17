require 'rubygems'
require 'spork'

#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'
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

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

  # Use test-specific translations
  AlaveteliLocalization.set_default_text_domain('app', File.join(File.dirname(__FILE__), 'fixtures', 'locale'))

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
                             :has_tag_string_tags,
                             :holidays

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
    config.order = "random"

    # This is a workaround for a strange thing where ActionMailer::Base.deliveries isn't being
    # cleared out correctly in controller specs. So, do it here for everything.
    config.before(:each) do
      ActionMailer::Base.deliveries = []
    end

    # Any test that messes with the locale needs to restore the state afterwards so that it
    # doesn't interfere with any subsequent tests. This is made more complicated by the
    # ApplicationController#set_gettext_locale which sets the locale and so you may be setting
    # the locale in your tests and not even realising it. So, let's make things easier for
    # ourselves and just always restore the locale for all tests.
    config.after(:each) do
      AlaveteliLocalization.set_locales(AlaveteliConfiguration::available_locales,
                                        AlaveteliConfiguration::default_locale)
    end

    # Turn routing-filter off in functional and unit tests as per
    # https://github.com/svenfuchs/routing-filter/blob/master/README.markdown#testing
    config.before(:each) do
      RoutingFilter.active = false if [:controller, :helper, :model].include? example.metadata[:type]
    end

    config.after(:each) do
      RoutingFilter.active = true if [:controller, :helper, :model].include? example.metadata[:type]
    end

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
  end

  # XXX No idea what namespace/class/module to put this in
  # Create a clean xapian index based on the fixture files and the raw_email data.
  def create_fixtures_xapian_index
      load_raw_emails_data
      rebuild_xapian_index
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
      username = AlaveteliConfiguration::admin_username if username.nil?
      password = AlaveteliConfiguration::admin_password if password.nil?
      request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{username}:#{password}")
  end
end

Spork.each_run do
    FactoryGirl.definition_file_paths = [ Rails.root.join('spec', 'factories') ]
    FactoryGirl.reload
  # This code will be run each time you run your specs.
end
