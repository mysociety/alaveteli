module Search
  module Adapters
    module Xapian
      ##
      # Service for finding similar requests using Xapian search.
      # Encapsulates common functionality used by both controllers and models.
      #
      class SimilarRequests < Adapter
        attr_reader :info_request

        def initialize(info_request)
          @info_request = info_request
          super(nil, {})
        end

        # Find similar requests - returns SearchResults collection
        def results(page: 1, per_page: 10)
          offset = calculate_offset(page, per_page)
          xapian_search = create_xapian_search(offset: offset, limit: per_page)

          ids, total_estimate = perform_similar_search(xapian_search)
          requests = load_info_requests(ids)

          create_search_results(
            items: requests,
            total_estimate: total_estimate,
            current_page: page,
            per_page: per_page,
            offset: offset
          )
        end

        # Find limited similar requests (for backwards compatibility)
        # Returns [requests, more_available]
        def first(limit = 10)
          super(limit)
        end

        private

        def create_xapian_search(offset: 0, limit: 10)
          ActsAsXapian::Similar.new(
            [InfoRequestEvent],
            info_request.info_request_events,
            offset: offset,
            limit: limit,
            collapse_by_prefix: 'request_collapse'
          )
        end

        def perform_similar_search(xapian_search)
          ids = []
          total_estimate = 0

          begin
            total_estimate = xapian_search.matches_estimated
            ids = extract_request_ids(xapian_search.results)
          rescue => e
            Rails.logger.warn "Search failed: #{e.message} " \
              "(info_request_id: #{info_request.id})"
          end

          [ids, total_estimate]
        end

        def extract_request_ids(results)
          results.map { |result| result[:model].info_request_id }
        end
      end
    end
  end
end
