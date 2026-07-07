module Search
  module Adapters
    module Xapian
      ##
      # Request search for Xapian. Runs the InfoRequestEvent full-text search
      # with request collapsing, then returns the InfoRequest behind each
      # matching event, so results are one InfoRequest per request and match
      # the shape the PostgreSQL request search produces.
      #
      class RequestSearch < Adapter
        def initialize(query, sort_by: nil, sort_ascending: true)
          @full_text_search = FullTextSearch.new(
            query,
            models: [InfoRequestEvent],
            sort_by_prefix: sort_by,
            sort_by_ascending: sort_ascending,
            collapse_by_prefix: 'request_collapse'
          )
          super(query, {})
        end

        def results(page: 1, per_page: 25)
          events = @full_text_search.results(page: page, per_page: per_page)
          requests = events.results.filter_map { |r| r[:model]&.info_request }

          create_search_results(
            items: requests.map { |request| { model: request } },
            total_estimate: events.total_estimate,
            current_page: page,
            per_page: per_page,
            offset: events.offset,
            words_to_highlight: events.words_to_highlight
          )
        end
      end
    end
  end
end
