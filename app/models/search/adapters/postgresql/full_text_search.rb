module Search
  module Adapters
    module Postgresql
      ##
      # Relevance-ordered, paginated full-text search over the
      # +search_documents+ table, wrapping SearchDocument.hybrid_search in the
      # Search::Results interface.
      #
      # Pagination slices an in-memory window of ranked rows. The inner query
      # has no cheap window-function count, so +total_estimate+ reports the
      # number of fetched rows rather than the full match count.
      #
      class FullTextSearch < Adapter
        attr_reader :query_string, :models

        def initialize(query_string, models:, admin_mode: false,
                       exact_mode: false, language: nil)
          @query_string = query_string
          @models = Array(models)
          if @models.size > 1
            raise ArgumentError,
                  'PostgreSQL search supports a single model or none'
          end
          @model = @models.first
          @admin_mode = admin_mode
          @exact_mode = exact_mode
          @language = language
          super(query_string, {})
        end

        def results(page: 1, per_page: 25)
          offset = calculate_offset(page, per_page)
          records = ranked_records(limit: offset + per_page)
          page_records = records[offset, per_page] || []

          create_search_results(
            # mirror the Xapian search result shape: each item is a hash
            # carrying the matched record under :model.
            items: page_records.map { |record| { model: record } },
            total_estimate: records.size,
            current_page: page,
            per_page: per_page,
            offset: offset
          )
        end

        private

        def ranked_records(limit:)
          SearchDocument.hybrid_search(
            @query_string,
            model: @model,
            language: @language,
            admin_mode: @admin_mode,
            exact_mode: @exact_mode,
            order_by_score: true,
            limit: limit
          ).to_a
        end
      end
    end
  end
end
