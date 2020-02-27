class InfoRequest
  module Prominence
    class BeenPublishedQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.joins(
          'LEFT JOIN "embargoes" ' \
          'ON "embargoes"."info_request_id" = "info_requests"."id"'
        ).joins(
          'LEFT JOIN "info_request_events" ' \
          'ON "info_request_events"."info_request_id" = "info_requests"."id"'
        ).where(
          '"embargoes"."id" IS NULL ' \
          'OR "info_request_events"."event_type" = ?', 'expire_embargo'
        )
      end
    end
  end
end
