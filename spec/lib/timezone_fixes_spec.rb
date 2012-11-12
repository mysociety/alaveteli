# This is a test of the monkey patches in timezone_fixes.rb

# We use MailServerLogDone here just as a totally random model that has a datetime type.
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when doing things with timezones" do

  it "should preserve time objects with local time conversion to default timezone UTC
      and return them as UTC times when config.time_zone is UTC" do
    with_env_tz 'America/New_York' do
      with_active_record_default_timezone :utc do
        time = Time.local(2000)
        mail_server_log_done = MailServerLogDone.create('last_stat' => time, 'filename' => 'dummy')
        raw_saved_time = MailServerLogDone.find(mail_server_log_done.id).read_attribute(:last_stat)
        saved_time = MailServerLogDone.find(mail_server_log_done.id).last_stat
        assert_equal time, saved_time
        assert_equal saved_time, raw_saved_time
        # Time is created in EST by local method (using ENV['TZ'])
        assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "EST"], time.to_a
        # Due to :utc active_record_default_timezone, everything saved as UTC
        assert_equal [0, 0, 5, 1, 1, 2000, 6, 1, false, "UTC"], raw_saved_time.to_a
        # As config.time_zone is UTC (from config default), times returned in UTC
        assert_equal [0, 0, 5, 1, 1, 2000, 6, 1, false, "UTC"], saved_time.to_a
      end
    end
  end

  it "should preserve time objects with time with zone conversion to default timezone UTC
      and return them as local times in the zone set by Time.use_zone" do

    with_env_tz 'America/New_York' do
      with_active_record_default_timezone :utc do
        Time.use_zone 'Central Time (US & Canada)' do
          time = Time.zone.local(2000)
          mail_server_log_done = MailServerLogDone.create('last_stat' => time, 'filename' => 'dummy')
          raw_saved_time = MailServerLogDone.find(mail_server_log_done.id).read_attribute(:last_stat)
          saved_time = MailServerLogDone.find(mail_server_log_done.id).last_stat
          assert_equal time, saved_time
          assert_equal saved_time, raw_saved_time
          # Time is created in CST by Time.local (as Time.zone has been set)
          assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "CST"], time.to_a
          # Due to :utc active_record_default_timezone, everything saved as UTC
          assert_equal [0, 0, 6, 1, 1, 2000, 6, 1, false, "UTC"], raw_saved_time.to_a
          # Times returned in CST due to Time.use_zone and ActiveRecord::time_zone_aware_attributes
          # being true
          assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "CST"], saved_time.to_a
        end
      end
    end
  end

  it "should preserve time objects with UTC time conversion to default timezone local
      and return then as UTC times when config.time_zone is UTC" do
   with_env_tz 'America/New_York' do
     with_active_record_default_timezone :local do
       time = Time.utc(2000)
       mail_server_log_done = MailServerLogDone.create('last_stat' => time, 'filename' => 'dummy')
       raw_saved_time = MailServerLogDone.find(mail_server_log_done.id).read_attribute(:last_stat)
       saved_time = MailServerLogDone.find(mail_server_log_done.id).last_stat
       assert_equal time, saved_time
       assert_equal saved_time, raw_saved_time
       # Time is created in UTC by Time.utc method
       assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "UTC"], time.to_a
       # Due to :local active_record_default_timezone, saved as EST
       assert_equal [0, 0, 19, 31, 12, 1999, 5, 365, false, "EST"], raw_saved_time.to_a
       # As config.time_zone is UTC (from config default), times returned in UTC
       assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "UTC"], saved_time.to_a
     end
   end
  end

  it "should preserve time objects with time with zone conversion to default timezone local
      and return them as local times in the zone set by Time.use_zone" do
    with_env_tz 'America/New_York' do
      with_active_record_default_timezone :local do
        Time.use_zone 'Central Time (US & Canada)' do
          time = Time.zone.local(2000)
          mail_server_log_done = MailServerLogDone.create('last_stat' => time, 'filename' => 'dummy')
          raw_saved_time = MailServerLogDone.find(mail_server_log_done.id).read_attribute(:last_stat)
          saved_time = MailServerLogDone.find(mail_server_log_done.id).last_stat
          assert_equal time, saved_time
          assert_equal saved_time, raw_saved_time
          # Time is created in CST by Time.zone.local
          assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "CST"], time.to_a
          # Due to :local active_record_default_timezone, saved as EST
          assert_equal [0, 0, 1, 1, 1, 2000, 6, 1, false, "EST"], raw_saved_time.to_a
          # Due to Time.use_zone, and ActiveRecord::time_zone_aware_attributes
          # being true, time returned in CST
          assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "CST"], saved_time.to_a
        end
      end
    end
  end


 protected

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
end


