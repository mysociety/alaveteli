class InfoRequest
  module Prominence
    class EverEmbargoedQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.joins(:info_request_events).
          where(info_request_events: { event_type: 'set_embargo' })
      end
    end
  end
end
