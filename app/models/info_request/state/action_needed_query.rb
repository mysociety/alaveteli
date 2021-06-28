class InfoRequest
  module State
    class ActionNeededQuery
      def initialize(relation = InfoRequest)
        @relation = relation
      end

      def call
        # A combination of response_received, clarification_needed, overdue
        # and very_overdue
        query = <<-SQL
awaiting_description = ?
OR (
  awaiting_description = ?
  AND (
    (described_state = 'waiting_clarification')
    OR (described_state = 'waiting_response' AND date_response_required_by < ?)
  )
)
SQL
        @relation.where(query, true, false, Time.zone.now.to_date)
      end
    end
  end
end
