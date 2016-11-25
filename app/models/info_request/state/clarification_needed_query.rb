# -*- encoding : utf-8 -*-
class InfoRequest
  module State
    class ClarificationNeededQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(described_state: 'waiting_clarification',
                        awaiting_description: false)
      end
    end
  end
end
