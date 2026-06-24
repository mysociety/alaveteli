require_relative 'postgresql/full_text_search'
require_relative 'postgresql/typeahead'
require_relative 'postgresql/similar'

module Search
  module Adapters
    module Postgresql
      ##
      # PostgreSQL search backend implementing the Search::Backend interface.
      #
      # The database is itself the search index: queries run against the
      # +search_documents+ table via SearchDocument.hybrid_search, and indexing
      # is a SearchDocument upsert done inline via the record's #reindex.
      #
      class Adapter < Search::Backend
        # Full-text search over the request's own indexed content, returning
        # one InfoRequest per match. Searching the messages and attachments
        # behind a request is follow-on work.
        def request_search(query, **)
          FullTextSearch.new(query, models: [InfoRequest])
        end

        # Full-text search returning a paginated, relevance-ordered
        # Postgresql::FullTextSearch (a Search::Results producer).
        #
        # Accepts the Xapian-style ranking options (+sort_by+,
        # +sort_ascending+, +collapse_by+) for interface compatibility but does
        # not yet act on them; ordering and collapsing are follow-on work.
        def search(query, models:, admin_mode: false, exact_mode: false,
                   language: nil, **)
          FullTextSearch.new(
            query,
            models: models,
            admin_mode: admin_mode,
            exact_mode: exact_mode,
            language: language
          )
        end

        # Full-text search constrained to +relation+, returning the joined
        # ActiveRecord::Relation directly so callers can compose further
        # conditions and ordering.
        def search_scope(query, relation, admin_mode: false, exact_mode: false,
                         language: nil, limit: 1000, **)
          SearchDocument.hybrid_search(
            query,
            relation: relation,
            admin_mode: admin_mode,
            exact_mode: exact_mode,
            language: language,
            limit: limit
          )
        end

        def typeahead(query, model:, exclude_tags: [], language: nil, **)
          Typeahead.new(
            query, model: model, exclude_tags: exclude_tags, language: language
          )
        end

        def similar(record)
          Similar.new(record)
        end

        # Reindex the record. The database is itself the search index, so the
        # work is a SearchDocument upsert done inline via the record's
        # #reindex; queued_jobs_count stays at the base class default of zero.
        def reindex_later(record)
          record.reindex
        end
      end
    end
  end
end
