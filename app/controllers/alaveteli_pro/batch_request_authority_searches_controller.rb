# -*- encoding : utf-8 -*-
class AlaveteliPro::BatchRequestAuthoritySearchesController < AlaveteliPro::BaseController
  MAX_RESULTS = 500

  before_action :check_user_has_batch_access

  def index
    @draft_batch_request = find_or_initialise_draft
    @body_ids_added = @draft_batch_request.public_body_ids
    # perform_seach sets @query but typeahead_search doesn't
    @query = params[:authority_query] || ""
    @search = typeahead_search(@query, { :model => PublicBody,
                                         :exclude_tags => [ 'defunct' ] })
    unless @search.blank?
      @result_limit = calculate_result_limit(@search)
      check_page_limit!(@page, @per_page)
    end

    if request.xhr?
      render :partial => 'search_results',
             :layout => false,
             :locals => {
               :search => @search,
               :draft_batch_request => @draft_batch_request,
               :body_ids_added => @body_ids_added,
               :query => @query,
               :page => @page,
               :per_page => @per_page,
               :result_limit => @result_limit
             }
    end
  end

  def new
    redirect_to alaveteli_pro_batch_request_authority_searches_path
  end

  private

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

  def check_user_has_batch_access
    unless (feature_enabled?(:pro_batch_access, current_user) &&
            current_user.pro_account &&
            current_user.pro_account.batches_remaining > 0)
      redirect_to new_alaveteli_pro_info_request_path
    end
    return true
  end

  def find_or_initialise_draft
    if params[:draft_id]
      current_user.draft_info_request_batches.find(params[:draft_id])
    else
      AlaveteliPro::DraftInfoRequestBatch.new
    end
  end
end
