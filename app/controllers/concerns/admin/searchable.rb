##
# Lets an admin listing switch between the legacy database search and the
# new search index.
#
# Usage:
#   class AdminUserController < AdminController
#     include Admin::Searchable
#
#     def index
#       users = legacy_search? ? legacy_user_scope : indexed_user_scope
#       @admin_users = users.paginate(page: params[:page])
#     end
#   end
#
module Admin::Searchable
  extend ActiveSupport::Concern

  included do
    helper_method :search_engine, :legacy_search?
  end

  def search_engine
    @search_engine ||= params[:search_engine] == 'legacy' ? 'legacy' : 'new'
  end

  def legacy_search?
    search_engine == 'legacy'
  end
end
