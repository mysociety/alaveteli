# -*- encoding : utf-8 -*-
class InfoRequestBatchController < ApplicationController
  before_filter :set_in_pro_area, :only => [:show]

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

end
