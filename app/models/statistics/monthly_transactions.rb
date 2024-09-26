class Statistics::MonthlyTransactions
  include Enumerable

  def initialize(start_year: nil, start_month: nil, end_year: nil, end_month: nil)
    @start_year = (start_year || InfoRequest.first.created_at.year).to_i
    @start_month = (start_month || 1).to_i
    @end_year = (end_year || Time.zone.now.year).to_i
    @end_month = (end_month || Time.zone.now.month).to_i
  end

  def to_a
    each_month.unshift(headers)
  end

  def each
    yield(headers)

    month_starts.each do |month_start|
      yield(monthly_transactions(month_start))
    end
  end

  def headers
    ['Period',
     'Requests sent',
     'Pro requests sent',
     'Visible comments',
     'Track this request email signups',
     'Comments on own requests',
     'Follow up messages sent',
     'Confirmed users',
     'Confirmed pro users',
     'Request classifications',
     'Public body change requests',
     'Widget votes',
     'Total tracks']
  end

  protected

  attr_reader :start_year
  attr_reader :start_month
  attr_reader :end_year
  attr_reader :end_month

  private

  def month_starts
    (Date.new(start_year, start_month)..Date.new(end_year, end_month)).
      select { |d| d.day == 1 }
  end

  def monthly_transactions(month_start)
    month_end = month_start.end_of_month
    period = "#{month_start}-#{month_end}"

    date_conditions = ['created_at >= ?
                        AND created_at < ?',
                       month_start, month_end+1]

    request_count = InfoRequest.where(date_conditions).count
    pro_request_count = InfoRequest.pro.where('info_requests.created_at >= ?
                                              AND info_requests.created_at < ?',
                                              month_start, month_end+1).count
    visible_comments_count = Comment.visible.where('comments.created_at >= ?
                                                    AND comments.created_at < ?',
                                                    month_start, month_end+1).count

    track_conditions = ['track_type = ?
                         AND track_medium = ?
                         AND created_at >= ?
                         AND created_at < ?',
                        'request_updates',
                        'email_daily',
                        month_start,
                        month_end + 1]
    email_request_track_count = TrackThing.where(track_conditions).count

    comment_on_own_request_conditions = ['comments.user_id = info_requests.user_id
                                          AND comments.created_at >= ?
                                          AND comments.created_at < ?',
                                         month_start, month_end+1]

    comment_on_own_request_count =
      Comment.
        includes(:info_request).
          references(:info_request).
            where(comment_on_own_request_conditions).
              count

    followup_date_range =
      ['created_at >= ? AND created_at < ?', month_start, month_end + 1]

    follow_up_count =
      OutgoingMessage.followup.is_searchable.where(followup_date_range).count

    confirmed_users_count =
      User.active.
        where(email_confirmed: true).
          where(date_conditions).
            count

    pro_confirmed_users_count =
      User.pro.active.
        where(email_confirmed: true).
          where('users.created_at >= ?
                 AND users.created_at < ?',
                 month_start, month_end+1).
            count

    request_classifications_count =
      RequestClassification.where(date_conditions).count

    public_body_change_requests_count =
      PublicBodyChangeRequest.where(date_conditions).count

    widget_votes_count = WidgetVote.where(date_conditions).count

    total_tracks_count = TrackThing.where(date_conditions).count

    [period,
     request_count,
     pro_request_count,
     visible_comments_count,
     email_request_track_count,
     comment_on_own_request_count,
     follow_up_count,
     confirmed_users_count,
     pro_confirmed_users_count,
     request_classifications_count,
     public_body_change_requests_count,
     widget_votes_count,
     total_tracks_count]
  end
end
