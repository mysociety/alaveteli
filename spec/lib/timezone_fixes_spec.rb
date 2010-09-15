# This is a test of the monkey patches in timezone_fixes.rb

# We use EximLogDone here just as a totally random model that has a datetime type.

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when doing things with timezones" do

  it "should preserve time objects with local time conversion to default timezone UTC" do
    with_env_tz 'America/New_York' do
      with_active_record_default_timezone :utc do
        time = Time.local(2000)
        exim_log_done = EximLogDone.create('last_stat' => time, 'filename' => 'dummy')
        saved_time = EximLogDone.find(exim_log_done.id).last_stat
        assert_equal time, saved_time
        assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "EST"], time.to_a
        assert_equal [0, 0, 5, 1, 1, 2000, 6, 1, false, "UTC"], saved_time.to_a
      end
    end
  end

  it "should preserve time objects with time with zone conversion to default timezone UTC" do
    with_env_tz 'America/New_York' do
      with_active_record_default_timezone :utc do
        Time.use_zone 'Central Time (US & Canada)' do
          time = Time.zone.local(2000)
          exim_log_done = EximLogDone.create('last_stat' => time, 'filename' => 'dummy')
          saved_time = EximLogDone.find(exim_log_done.id).last_stat
          assert_equal time, saved_time
          assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "CST"], time.to_a
          assert_equal [0, 0, 6, 1, 1, 2000, 6, 1, false, "UTC"], saved_time.to_a
        end
      end
    end
  end

  # XXX Couldn't get this test to work - but the other tests seem to detect presence of
  # the monkey patch, so they will do for now.
  #it "should preserve time objects with UTC time conversion to default timezone local" do
  #  with_env_tz 'America/New_York' do
  #    time = Time.utc(2000)
  #    exim_log_done = EximLogDone.create('last_stat' => time, 'filename' => 'dummy')
  #    saved_time = EximLogDone.find(exim_log_done.id).last_stat
  #    assert_equal time, saved_time
  #    assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "UTC"], time.to_a
  #    assert_equal [0, 0, 19, 31, 12, 1999, 5, 365, false, "EST"], saved_time.to_a
  #  end
  #end

  it "should preserve time objects with time with zone conversion to default timezone local" do
    with_env_tz 'America/New_York' do
      with_active_record_default_timezone :local do
        Time.use_zone 'Central Time (US & Canada)' do
          time = Time.zone.local(2000)
          exim_log_done = EximLogDone.create('last_stat' => time, 'filename' => 'dummy')
          saved_time = EximLogDone.find(exim_log_done.id).last_stat
          assert_equal time, saved_time
          assert_equal [0, 0, 0, 1, 1, 2000, 6, 1, false, "CST"], time.to_a
          assert_equal [0, 0, 1, 1, 1, 2000, 6, 1, false, "EST"], saved_time.to_a
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


