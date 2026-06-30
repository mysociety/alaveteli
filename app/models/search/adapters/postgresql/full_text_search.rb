module Search
  module Adapters
    module Postgresql
      ##
      # Relevance-ordered, paginated full-text search over the
      # +search_documents+ table, wrapping the ranked documents in the
      # Search::Results interface.
      #
      # A search may span several models, so it ranks documents (not a single
      # model's rows) and resolves each to its searchable record, mirroring the
      # Xapian search result shape of +{ model: record }+ items.
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
          @admin_mode = admin_mode
          @exact_mode = exact_mode
          @language = language
          super(query_string, {})
        end

        def results(page: 1, per_page: 25)
          offset = calculate_offset(page, per_page)
          documents = ranked_documents(limit: offset + per_page)
          page_documents = documents[offset, per_page] || []

          create_search_results(
            items: searchables(page_documents).map { |r| { model: r } },
            total_estimate: documents.size,
            current_page: page,
            per_page: per_page,
            offset: offset
          )
        end

        private

        def ranked_documents(limit:)
          SearchDocument.ranked_documents(
            @query_string,
            models: @models,
            language: @language,
            admin_mode: @admin_mode,
            exact_mode: @exact_mode,
            limit: limit
          ).to_a
        end

        # Load each document's searchable record, preserving rank order and
        # dropping any whose record has since been deleted.
        def searchables(documents)
          ActiveRecord::Associations::Preloader.new(
            records: documents, associations: :searchable
          ).call
          documents.map(&:searchable).compact
        end
      end
    end
  end
end
