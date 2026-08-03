module Search
  module Adapters
    module Postgresql
      ##
      # PostgreSQL search backend implementing the scoped-search part of the
      # Search::Backend interface.
      #
      # The database is itself the search index: queries run against the
      # +search_documents+ table via SearchDocument.hybrid_search, and indexing
      # is a SearchDocument upsert done inline via the record's #reindex.
      #
      # The paginated query interface (search, typeahead, similar) is
      # follow-on work; those methods keep the base class's
      # NotImplementedError behaviour.
      #
      class Adapter < Search::Backend
        # Full-text search constrained to +relation+, returning the joined
        # ActiveRecord::Relation directly so callers can compose further
        # conditions and ordering.
        def search_scope(query, relation, admin_mode: false, exact_mode: false,
                         case_sensitive: true, language: nil, limit: 1000,
                         weights: nil, except: nil, **)
          SearchDocument.hybrid_search(
            query,
            relation: relation,
            admin_mode: admin_mode,
            exact_mode: exact_mode,
            case_sensitive: case_sensitive,
            language: language,
            limit: limit,
            weights: weights,
            except: except
          )
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
