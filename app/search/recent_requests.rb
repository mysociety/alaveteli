module Search
  ##
  # Finds recent successful and sent requests for the front page.
  #
  class RecentRequests
    MAX_COUNT = 5

    include EventSearch

    def call
      request_events = []
      request_events_all_successful = false

      begin
        query = 'variety:response ' \
                '(status:successful OR status:partially_successful)'

        results = search_events(query,
                                limit: MAX_COUNT,
                                collapse_by: 'request_title_collapse')
        request_events = results.results.map { |r| r[:model] }

        if request_events.count < MAX_COUNT
          query = 'variety:sent'
          more = search_events(query,
                               limit: MAX_COUNT - request_events.count,
                               collapse_by: 'request_title_collapse')
          request_events += more.results.map { |r| r[:model] }
          request_events.sort! { |e1, e2| e2.created_at <=> e1.created_at }
        else
          request_events_all_successful = true
        end
      rescue StandardError
        request_events = []
      end

      [request_events, request_events_all_successful]
    end
  end
end
