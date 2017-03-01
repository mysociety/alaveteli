# -*- encoding : utf-8 -*-
class AlaveteliPro::BatchRequestAuthoritySearchesController < AlaveteliPro::BaseController
  MAX_RESULTS = 500

  def new
    render 'search_results'
  end

  def create
    @search = perform_search(params[:query])
    @result_limit = calculate_result_limit(@search)
    check_page_limit!(@page, @per_page)
    render 'search_results'
  end

  private

  def perform_search(query)
    sortby = 'relevant'
    collapse = nil
    models = [PublicBody]
    super(models, query, sortby, collapse)
  end

  # Limit the result count
  def calculate_result_limit(search)
    (search.matches_estimated > MAX_RESULTS) ? MAX_RESULTS : search.matches_estimated
  end

  def check_page_limit!(page, per_page)
    # Later pages are very expensive to load
    if page > MAX_RESULTS / per_page
      raise ActiveRecord::RecordNotFound.new("Sorry. No pages after #{MAX_RESULTS / per_page}.")
    end
  end
end
