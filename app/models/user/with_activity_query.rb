# Beta: Add an 'activity' attribute to User to approximate how much the User is
# interacting with the application.
#
# Examples:
#
#   q = User::WithActivityQuery.new
#   q.call
#   # => User::ActiveRecord_Relation
#
#   # ID of most active user:
#   q.call.order('activity DESC').first.id
#   # => 19
#
#   # Activity in date range:
#   q.call(1.month.ago..Time.zone.now)
#   # => User::ActiveRecord_Relation
#
#   # Count of users active in the period
#   # Note the use of `count(:all)` here. I don't fully understand the issue,
#   # but see https://github.com/rails/rails/issues/13648#issuecomment-39352347
#   # for more information.
#   q.call(2.days.ago..1.day.ago).count(:all)
#   # => 22
#
#   # Just pluck User id and activity for specific users:
#   q.call.where(:id => [2, 10]).pluck('id, activity')
#   # => [[2, nil],
#   #     [10, 75]]
class User
  class WithActivityQuery
    def initialize(relation = User)
      @relation = relation
    end

    def call(between = nil)
      @relation.select(select_sql).joins(joins_sql(between))
    end

    private

    def select_sql
      <<-EOF.strip_heredoc
        "users".*,
        COALESCE("info_request_events"."activity", 0) AS activity
      EOF
    end

    def joins_sql(between = nil)
      between_filter =
        if between
          %Q(AND ("info_request_events"."created_at"
             BETWEEN '#{ between.first }'
             AND '#{ between.last }'))
        end

      <<-EOF.strip_heredoc.squish
      LEFT JOIN (
        SELECT "info_requests"."user_id",
               COUNT("info_request_events".*) AS "activity"
        FROM "info_requests"
        LEFT JOIN "info_request_events"
        ON "info_request_events"."info_request_id" = "info_requests"."id"
        WHERE "info_requests"."user_id" IS NOT NULL
        AND "info_request_events"."event_type"
        IN ('comment','set_embargo','sent', 'followup_sent', 'status_update')
        #{ between_filter }
        GROUP BY "info_requests"."user_id"
      ) "info_request_events" ON "info_request_events"."user_id" = "users"."id"
      EOF
    end
  end
end
