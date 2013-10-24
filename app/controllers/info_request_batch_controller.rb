class InfoRequestBatchController < ApplicationController

    def show
        @info_request_batch = InfoRequestBatch.find(params[:id])
    end

end
