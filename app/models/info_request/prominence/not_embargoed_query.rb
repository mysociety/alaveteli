class InfoRequest
  module Prominence
    class NotEmbargoedQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.left_joins(:embargo).where(embargoes: { id: nil })
      end
    end
  end
end
