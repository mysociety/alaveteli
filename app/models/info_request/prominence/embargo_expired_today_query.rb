# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    class EmbargoExpiredTodayQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.
          includes(:embargo).
          joins(:info_request_events).
          where('embargoes.info_request_id IS NULL').
          where([
            'info_request_events.created_at >= ?',
            Time.zone.now.beginning_of_day
          ]).
          where(info_request_events: { event_type: 'expire_embargo' }).
          references(:embargoes, :info_request_events)
      end
    end
  end
end
