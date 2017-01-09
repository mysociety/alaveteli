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
            .where("embargoes.publish_at <= ?", Time.zone.now + 1.week)
      end
    end
  end
end
