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
      # +collapse_by+ 'request_collapse' returns one InfoRequest per matching
      # request (the request behind whichever record matched), matching the
      # request listing the view expects. Collapsing happens after ranking, so
      # it oversamples the ranked window; the result count (and so
      # +total_estimate+) is the collapsed size of that window rather than the
      # full match count.
      #
      class FullTextSearch < Adapter
        attr_reader :query_string, :models

        # how many ranked documents to fetch per requested result when
        # collapsing, to leave room for the rows collapsing removes.
        COLLAPSE_OVERSAMPLE = 3

        def initialize(query_string, models:, admin_mode: false,
                       exact_mode: false, language: nil, collapse_by: nil)
          @query_string = query_string
          @models = Array(models)
          @admin_mode = admin_mode
          @exact_mode = exact_mode
          @language = language
          @collapse_by = collapse_by
          super(query_string, {})
        end

        def results(page: 1, per_page: 25)
          offset = calculate_offset(page, per_page)
          documents = ranked_documents(limit: fetch_limit(offset, per_page))
          records = searchables(documents)
          records = collapse_by_request(records) if collapse_requests?
          page_records = records[offset, per_page] || []

          create_search_results(
            items: page_records.map { |record| { model: record } },
            total_estimate: records.size,
            current_page: page,
            per_page: per_page,
            offset: offset,
            words_to_highlight: highlight_terms
          )
        end

        private

        # Terms the view highlights in results: the query's own words, matched
        # case-insensitively by the highlight helper. Highlighting stemmed
        # variants, the way Xapian does, is follow-on.
        def highlight_terms
          @query_string.to_s.scan(/[[:word:]]+/).uniq
        end

        def fetch_limit(offset, per_page)
          window = offset + per_page
          collapse_requests? ? window * COLLAPSE_OVERSAMPLE : window
        end

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

        def collapse_requests?
          @collapse_by == 'request_collapse'
        end

        # Collapse to info requests: each result becomes the InfoRequest the
        # matched record belongs to (the request itself, or the request behind
        # an event, outgoing or incoming message), keeping rank order and the
        # first (highest ranked) occurrence of each request. Records not tied to
        # a request are dropped, as request collapse produces a request listing.
        def collapse_by_request(records)
          seen = Set.new
          ordered_ids = records.
            filter_map { |record| request_id_for(record) }.
            select { |id| seen.add?(id) }

          by_id = InfoRequest.where(id: ordered_ids).index_by(&:id)
          ordered_ids.filter_map { |id| by_id[id] }
        end

        def request_id_for(record)
          return record.id if record.is_a?(InfoRequest)
          return record.info_request_id if record.respond_to?(:info_request_id)

          record.info_request&.id if record.respond_to?(:info_request)
        end
      end
    end
  end
end
