class InfoRequest
  module Prominence
    class NeverEmbargoedQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where.not(
          InfoRequest.from(InfoRequest.arel_table.alias('_ir')).
            where('"info_requests"."id" = "_ir"."id"').
            joins(:info_request_events).
            where(info_request_events: { event_type: 'set_embargo' }).
            select(1).
            arel.
            exists
        )
      end
    end
  end
end
