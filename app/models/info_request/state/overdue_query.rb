class InfoRequest
  module State
    class OverdueQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        @relation
          .where(described_state: ['waiting_response'])
            .where("date_response_required_by < ?", Time.zone.now.to_date)
              .where("date_very_overdue_after >= ?", Time.zone.now.to_date)
      end
    end
  end
end
