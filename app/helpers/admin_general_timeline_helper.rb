##
# Helpers for rendering timeline filter buttons. Also used in the controller for
# generating the queries to load events.
#
module AdminGeneralTimelineHelper
  def start_date
    params[:start_date]&.to_datetime || 2.days.ago
  end

  def time_filters
    {
      'Hour' => 1.hour.ago,
      'Day' => 1.day.ago,
      '2 days' => 2.days.ago,
      'Week' => 1.week.ago,
      'Month' => 1.month.ago,
      'All time' => Time.utc(1970, 1, 1)
    }
  end

  def current_time_filter
    time_filters.min_by { |_, time| (time - start_date).abs }.first
  end

  def event_types
    {
      authority_change: 'Authority changes',
      info_request_event: 'Request events',
      all: 'All events'
    }
  end

  def current_event_type
    event_types[params[:event_type]&.to_sym] || event_types[:all]
  end
end
