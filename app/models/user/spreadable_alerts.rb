# Handles spreading alerts over the day so that we have a more even server load.
module User::SpreadableAlerts
  extend ActiveSupport::Concern

  included do
    after_initialize :set_alert_times
  end

  class_methods do
    # Used for default values of last_daily_track_email
    def random_time_in_last_day
      earliest_time = Time.zone.now - 1.day
      latest_time = Time.zone.now
      earliest_time + rand(latest_time - earliest_time).seconds
    end

    # Alters last_daily_track_email for every user, so alerts will be sent
    # spread out fairly evenly throughout the day, balancing load on the server.
    # This is intended to be called by hand from the Ruby console. It will mean
    # quite a few users may get more than one email alert the day you do it, so
    # have a care and run it rarely.
    #
    # This SQL statement is useful for seeing how spread out users are at the
    # moment:
    #
    # SELECT extract(hour from last_daily_track_email) AS h, COUNT(*)
    # FROM users
    # GROUP BY extract(hour from last_daily_track_email)
    # ORDER BY h;
    def spread_alert_times_across_day
      find_each do |user|
        user.update!(last_daily_track_email: random_time_in_last_day)
      end

      nil # so doesn't print all users on console
    end
  end

  private

  def set_alert_times
    return unless new_record?

    # make alert emails go out at a random time for each new user, so
    # overall they are spread out throughout the day.
    self.last_daily_track_email = self.class.random_time_in_last_day

    # Make daily summary emails go out at a random time for each new user
    # too, if it's not already set
    self.daily_summary_hour ||= self.class.random_time_in_last_day.hour
    self.daily_summary_minute ||= self.class.random_time_in_last_day.min
  end
end
