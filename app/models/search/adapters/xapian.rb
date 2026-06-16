require_relative 'xapian/indexing'
require_relative 'xapian/similar_requests'
require_relative 'xapian/full_text_search'
require_relative 'xapian/typeahead'

module Search
  module Adapters
    module Xapian
      ##
      # Xapian search backend implementing the Search::Backend interface.
      #
      class Adapter < Search::Backend
        def similar(record)
          SimilarRequests.new(record)
        end

        def search_scope(query, relation, **)
          model = relation.klass
          xapian_search = ActsAsXapian::Search.new(
            [model], query, offset: 0, limit: 1000
          )
          ids = xapian_search.results.map { |r| r[:model].id }
          relation.where(id: ids)
        end

        def search(query, models:, sort_by: nil, sort_ascending: true,
                   collapse_by: nil)
          FullTextSearch.new(
            query,
            models: models,
            sort_by_prefix: sort_by,
            sort_by_ascending: sort_ascending,
            collapse_by_prefix: collapse_by
          )
        end

        def typeahead(query, model:, exclude_tags: [])
          Typeahead.new(query, model: model, exclude_tags: exclude_tags)
        end

        def reindex_later(record)
          record.xapian_mark_needs_index
        end

        def queued_jobs_count
          ActsAsXapian::ActsAsXapianJob.count
        end
      end
    end
  end
end
