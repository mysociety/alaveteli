##
# Lets an admin listing switch between the legacy database search and the
# new search index, and reports what the search it ran cost.
#
# Usage:
#   class AdminUserController < AdminController
#     include Admin::Searchable
#
#     def index
#       users = legacy_search? ? legacy_user_scope : indexed_user_scope
#       @admin_users = measure_search(users.paginate(page: params[:page]))
#     end
#   end
#
module Admin::Searchable
  extend ActiveSupport::Concern

  included do
    helper_method :search_engine, :legacy_search?, :search_stats
  end

  attr_reader :search_stats

  def search_engine
    @search_engine ||= params[:search_engine] == 'legacy' ? 'legacy' : 'new'
  end

  def legacy_search?
    search_engine == 'legacy'
  end

  # Whether this listing is running a search that ranks what it finds.
  def indexed_search?
    params[:query].present? && !legacy_search?
  end

  # Run +relation+, timing it so the listing can show what the search cost.
  # Returns the relation, now loaded.
  def measure_search(relation)
    @search_stats = Search::Stats.measure(relation)
    relation
  end
end
