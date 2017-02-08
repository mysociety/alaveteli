# -*- encoding : utf-8 -*-
class InfoRequest
  module State
    class ResponseReceivedQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(awaiting_description: true)
      end
    end
  end
end
