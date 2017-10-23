# -*- encoding : utf-8 -*-

module NotificationMailerHelper
  # Group an array of notifications into a hash keyed by their
  # info_request_event's event_type string
  def notifications_by_event_type(notifications)
    notifications.group_by { |n| n.info_request_event.event_type }
  end
end
