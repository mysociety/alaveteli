class InfoRequest
  module Prominence
    class PublicQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(prominence: %w[normal backpage]).not_embargoed
      end
    end
  end
end
