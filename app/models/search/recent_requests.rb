module Search
  ##
  # Finds recent successful and sent requests for the front page.
  #
  # This is a listing, not a keyword search: it filters InfoRequests by state
  # directly rather than through the search index, so it does not depend on a
  # backend's structured-query support and returns InfoRequests.
  #
  class RecentRequests
    MAX_COUNT = 5

    SUCCESSFUL_STATES = %w[successful partially_successful].freeze

    def call
      successful = recent(SUCCESSFUL_STATES)
      return [successful, true] if successful.size >= MAX_COUNT

      requests = (successful + recent).uniq.first(MAX_COUNT)
      [requests, false]
    rescue StandardError
      [[], false]
    end

    private

    # The most recent searchable requests, optionally limited to given states.
    def recent(states = nil)
      scope = InfoRequest.is_searchable.order(created_at: :desc)
      scope = scope.where(described_state: states) if states
      scope.limit(MAX_COUNT).to_a
    end
  end
end
