module Statistics
  # Top 10 User records who've performed specific site actions
  class Leaderboard
    def all_time_requesters
      InfoRequest.is_public.
                  joins(:user).
                  merge(User.not_banned).
                  group(:user).
                  order(count_info_requests_all: :desc).
                  limit(10).
                  count
    end

    def last_28_day_requesters
      # TODO: Refactor as it's basically the same as all_time_requesters
      InfoRequest.is_public.
                  where('info_requests.created_at >= ?', 28.days.ago).
                  joins(:user).
                  merge(User.not_banned).
                  group(:user).
                  order(count_info_requests_all: :desc).
                  limit(10).
                  count
    end

    def all_time_commenters
      Comment.visible.
              joins(:user).
              merge(User.not_banned).
              group(:user).
              order(count_all: :desc).
              limit(10).
              count
    end

    def last_28_day_commenters
      # TODO: Refactor as it's basically the same as all_time_commenters
      Comment.visible.
              where('comments.created_at >= ?', 28.days.ago).
              joins(:user).
              merge(User.not_banned).
              group(:user).
              order(count_all: :desc).
              limit(10).
              count
    end
  end
end
