##
# The InfoRequestEvents on a user's wall: the latest event on each request
# the user made, and the comments the user wrote.
#
class User::Wall
  def initialize(user, limit: 20)
    @user = user
    @limit = limit
  end

  def events
    request_events + comment_events
  end

  private

  attr_reader :user, :limit

  def request_events
    latest = InfoRequestEvent.is_searchable.
      requested_by(user).
      group(:info_request_id).
      select('MAX(info_request_events.id)')

    newest(InfoRequestEvent.where(id: latest))
  end

  def comment_events
    newest(InfoRequestEvent.is_searchable.commented_by(user))
  end

  def newest(events)
    events.for_listing.newest.limit(limit).to_a
  end
end
