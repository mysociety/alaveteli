# -*- encoding : utf-8 -*-
class InfoRequestBatchController < ApplicationController
  before_filter :set_in_pro_area, :only => [:show]
  before_filter :redirect_embargoed_requests_for_pro_users, :only => [:show]
  before_filter :redirect_public_requests_from_pro_context, :only => [:show]

  def show
    @info_request_batch = InfoRequestBatch.find(params[:id])
    @per_page = 25
    @page = get_search_page_from_params

    if @info_request_batch.sent_at
      @info_requests =
        @info_request_batch.
          info_requests.
            is_searchable.
              offset((@page - 1) * @per_page).
                limit(@per_page)
    else
      @public_bodies =
        @info_request_batch.
          public_bodies.
            offset((@page - 1) * @per_page).
              limit(@per_page)
    end
  end

  def redirect_embargoed_requests_for_pro_users
    # Pro users should see their embargoed requests in the pro page, so that
    # if other site functions send them to a request page, they end up back in
    # the pro area
    if feature_enabled?(:alaveteli_pro) && \
       params[:pro] != "1" && current_user && current_user.is_pro?
      batch = InfoRequestBatch.find(params[:id])
      if batch.user == current_user && batch.embargo_duration
        redirect_to show_alaveteli_pro_batch_request_url(batch)
      end
    end
  end

  def redirect_public_requests_from_pro_context
    # Requests which aren't embargoed should always go to the normal request
    # page, so that pro's seem them in that context after they publish them
    if feature_enabled?(:alaveteli_pro) && params[:pro] == "1"
      batch = InfoRequestBatch.find(params[:id])
      unless batch.embargo_duration
        redirect_to info_request_batch_url(batch)
      end
    end
  end
end
