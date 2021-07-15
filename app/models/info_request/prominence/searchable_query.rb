class InfoRequest
  module Prominence
    class SearchableQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(prominence: 'normal').not_embargoed
      end
    end
  end
end

