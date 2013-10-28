class InfoRequestBatchController < ApplicationController

    def show
        @info_request_batch = InfoRequestBatch.find(params[:id])
        @per_page = 25
        @page = get_search_page_from_params
        @info_requests = @info_request_batch.info_requests.all(:offset => (@page - 1) * @per_page,
                                                               :limit => @per_page)
    end

end
