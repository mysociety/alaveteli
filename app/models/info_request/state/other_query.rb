class InfoRequest
  module State
    class OtherQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation.where(described_state: ['gone_postal',
                                          'internal_review',
                                          'error_message',
                                          'requires_admin',
                                          'attention_requested',
                                          'vexatious',
                                          'not_foi'],
                        awaiting_description: false)
      end
    end
  end
end
