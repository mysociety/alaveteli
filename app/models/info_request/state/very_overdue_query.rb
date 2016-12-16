class InfoRequest
  module State
    class VeryOverdueQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation
          .where(described_state: ['waiting_response'])
            .where("date_very_overdue_after < ?", Time.now.to_date)
      end
    end
  end
end
