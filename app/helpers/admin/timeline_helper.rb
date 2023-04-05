# For the admin timeline.
module TimelineHelper
  def time_filters
    { hour: 1, day: 1, week: 1, month: 1, all: 1 }
  end

  def event_types
    { authority_change: 'Authority changes',
      info_request_event: 'Request events',
      all: 'All' }
  end
end
