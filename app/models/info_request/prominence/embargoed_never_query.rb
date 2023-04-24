class InfoRequest
  module Prominence
    class EmbargoedNeverQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.
          joins(<<~SQL.squish).
            LEFT OUTER JOIN "info_request_events" ON
            "info_request_events"."info_request_id" = "info_requests"."id" AND
            "info_request_events"."event_type" = 'set_embargo'
          SQL
          group('info_requests.id').
          having('COUNT(info_request_events.id) = 0')
      end
    end
  end
end


