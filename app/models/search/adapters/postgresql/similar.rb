module Search
  module Adapters
    module Postgresql
      ##
      # Finds requests similar to a given one by running its own indexed text
      # back through the full-text search, scoped to InfoRequest and excluding
      # the source record.
      #
      # This is content-as-query similarity rather than term-vector overlap; it
      # is adequate for now and flagged for iteration.
      #
      class Similar < Adapter
        attr_reader :info_request

        def initialize(info_request)
          @info_request = info_request
          super(nil, {})
        end

        def results(page: 1, per_page: 10)
          offset = calculate_offset(page, per_page)
          records = similar_requests(limit: offset + per_page)

          create_search_results(
            items: records[offset, per_page] || [],
            total_estimate: records.size,
            current_page: page,
            per_page: per_page,
            offset: offset
          )
        end

        private

        def similar_requests(limit:)
          return [] if source_text.blank?

          SearchDocument.hybrid_search(
            source_text,
            relation: InfoRequest.where.not(id: info_request.id),
            order_by_score: true,
            limit: limit
          ).to_a
        end

        def source_text
          @source_text ||=
            SearchDocument.
              where(searchable: info_request).
              pluck(:raw_content).
              join(' ')
        end
      end
    end
  end
end
