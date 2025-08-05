# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    class NotEmbargoedQuery

      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        # Specify an outer join as the default inner join
        # will not retrieve NULL records which is what we want here
        @relation
          .select("info_requests.*")
            .joins('LEFT OUTER JOIN embargoes
                    ON embargoes.info_request_id = info_requests.id')
              .where('embargoes.id IS NULL')
                .references(:embargoes)
      end
    end
  end
end
