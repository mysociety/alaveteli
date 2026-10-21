class InfoRequest
  module Prominence
    class NotEmbargoedQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        # NOT IN, so PostgreSQL hashes the embargoed ids once. A join to
        # embargoes is planned badly for large lists.
        @relation.where.not(
          id: AlaveteliPro::Embargo.where.not(info_request_id: nil).
            select(:info_request_id)
        )
      end
    end
  end
end
