module Search
  module Adapters
    module Xapian
      ##
      # Adapter for full-text search using Xapian.
      # Wraps ActsAsXapian::Search with the Search::Results interface.
      #
      class FullTextSearch < Adapter
        attr_reader :query_string, :models

        def initialize(query_string, models:, sort_by_prefix: nil,
                       sort_by_ascending: true, collapse_by_prefix: nil)
          @query_string = query_string
          @models = Array(models)
          @sort_by_prefix = sort_by_prefix
          @sort_by_ascending = sort_by_ascending
          @collapse_by_prefix = collapse_by_prefix
          super(query_string, {})
        end

        def results(page: 1, per_page: 25)
          offset = calculate_offset(page, per_page)
          xapian_search = create_xapian_search(offset: offset, limit: per_page)

          create_search_results(
            items: xapian_search.results,
            total_estimate: xapian_search.matches_estimated,
            current_page: page,
            per_page: per_page,
            offset: offset,
            spelling_correction: xapian_search.spelling_correction,
            words_to_highlight: extract_words_to_highlight(xapian_search),
            has_normal_search_terms: xapian_search.has_normal_search_terms?
          )
        end

        private

        def create_xapian_search(offset:, limit:)
          ActsAsXapian::Search.new(
            @models,
            @query_string,
            offset: offset,
            limit: limit,
            sort_by_prefix: @sort_by_prefix,
            sort_by_ascending: @sort_by_ascending,
            collapse_by_prefix: @collapse_by_prefix
          )
        end

        def extract_words_to_highlight(xapian_search)
          xapian_search.words_to_highlight(include_original: true, regex: true)
        rescue StandardError
          []
        end
      end
    end
  end
end
