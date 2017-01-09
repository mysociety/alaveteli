# -*- encoding : utf-8 -*-
class InfoRequest
  module Prominence
    class EmbargoExpiringQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.includes(:embargo)
          .where('embargoes.id IS NOT NULL')
            .where("embargoes.publish_at <= ?", Embargo.expiring_soon_time)
      end
    end
  end
end
