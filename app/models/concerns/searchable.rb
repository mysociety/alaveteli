##
# Adds a chainable, backend-agnostic full-text search to indexed models.
#
# +search_scope+ runs the configured search backend over the current
# relation and returns an ActiveRecord::Relation, so it composes with
# other query conditions both before and after the search.
#
# @example
#   User.where.not(banned_at: nil).search_scope('alice').order(:created_at)
#
module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def search_scope(query, **options)
      Search.search_scope(query, all, **options)
    end
  end
end
