# -*- encoding : utf-8 -*-
class InfoRequestBatchController < ApplicationController

  def show
    @info_request_batch = InfoRequestBatch.find(params[:id])
    @per_page = 25
    @page = get_search_page_from_params
    if @info_request_batch.sent_at
      @info_requests = @info_request_batch.info_requests.visible.all(:offset => (@page - 1) * @per_page,
                                                                     :limit => @per_page)
    else
      @public_bodies = @info_request_batch.public_bodies.all(:offset => (@page - 1) * @per_page,
                                                             :limit => @per_page)
    end
  end

end
