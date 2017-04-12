# -*- encoding : utf-8 -*-
class InfoRequestBatchController < ApplicationController
  before_filter :set_in_pro_area, :only => [:show]
  before_filter :load_and_authorise_resource, :only => [:show]
  before_filter :redirect_embargoed_requests_for_pro_users, :only => [:show]
  before_filter :redirect_public_requests_from_pro_context, :only => [:show]

  def show
    @per_page = 25
    @page = get_search_page_from_params
    offset = (@page - 1) * @per_page
    if @info_request_batch.sent_at
      @info_requests = load_info_requests(offset)
    else
      @public_bodies = load_public_bodies(offset)
    end
  end

  def load_and_authorise_resource
    @info_request_batch = InfoRequestBatch.find(params[:id])
    if cannot?(:read, @info_request_batch)
      raise ActiveRecord::RecordNotFound
    end
  end

  def redirect_embargoed_requests_for_pro_users
    # Pro users should see their embargoed requests in the pro page, so that
    # if other site functions send them to a request page, they end up back in
    # the pro area
    if feature_enabled?(:alaveteli_pro) && \
       params[:pro] != "1" && current_user && current_user.is_pro?
      if @info_request_batch.user == current_user && \
         @info_request_batch.embargo_duration
        redirect_to show_alaveteli_pro_batch_request_url(@info_request_batch)
      end
    end
  end

  def redirect_public_requests_from_pro_context
    # Requests which aren't embargoed should always go to the normal request
    # page, so that pros see them in that context after they publish them
    if feature_enabled?(:alaveteli_pro) && params[:pro] == "1"
      unless @info_request_batch.embargo_duration
        redirect_to info_request_batch_url(@info_request_batch)
      end
    end
  end

  def load_info_requests(offset)
    if @info_request_batch.embargo_duration
      load_all_info_requests(offset)
    else
      load_searchable_info_requests(offset)
    end
  end

  def load_all_info_requests(offset)
    @info_request_batch.info_requests.offset(offset).limit(@per_page)
  end

  def load_searchable_info_requests(offset)
    @info_request_batch.info_requests.is_searchable.offset(offset).limit(@per_page)
  end

  def load_public_bodies(offset)
    @info_request_batch.public_bodies.offset(offset).limit(@per_page)
  end
end
