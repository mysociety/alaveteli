module Search
  module Adapters
    module Xapian
      ##
      # Adapter for typeahead/autocomplete search using Xapian.
      # Wraps the TypeaheadSearch class with the Search::Results interface.
      #
      class Typeahead < Adapter
        attr_reader :query_string, :model, :exclude_tags

        def initialize(query_string, model:, exclude_tags: [])
          @query_string = query_string
          @model = model
          @exclude_tags = Array(exclude_tags)
          super(query_string, {})
        end

        def results(page: 1, per_page: 25)
          typeahead = ::TypeaheadSearch.new(
            @query_string,
            model: @model,
            page: page,
            per_page: per_page,
            exclude_tags: @exclude_tags
          )

          xapian_result = typeahead.xapian_search
          return empty_results(page, per_page) if xapian_result.nil?

          offset = calculate_offset(page, per_page)

          create_search_results(
            items: xapian_result.results,
            total_estimate: xapian_result.matches_estimated,
            current_page: page,
            per_page: per_page,
            offset: offset,
            spelling_correction: xapian_result.spelling_correction,
            words_to_highlight: extract_words_to_highlight(xapian_result)
          )
        end

        private

        def empty_results(page, per_page)
          create_search_results(
            items: [],
            total_estimate: 0,
            current_page: page,
            per_page: per_page,
            offset: calculate_offset(page, per_page)
          )
        end

        def extract_words_to_highlight(xapian_result)
          xapian_result.words_to_highlight(include_original: true, regex: true)
        rescue StandardError
          []
        end
      end
    end
  end
end
