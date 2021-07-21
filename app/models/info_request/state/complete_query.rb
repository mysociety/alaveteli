class InfoRequest
  module State
    class CompleteQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(described_state: ['not_held',
                                          'rejected',
                                          'successful',
                                          'partially_successful',
                                          'user_withdrawn'],
                        awaiting_description: false)
      end
    end
  end
end
