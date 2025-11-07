class Admin::InfoRequestBatchesController < AdminController
  before_action :set_info_request_batch, :check_info_request_batch

  def show
    @info_requests =
      @info_request_batch.
      info_requests.
      paginate(page: params[:page], per_page: 100)
  end

  private

  def set_info_request_batch
    @info_request_batch = InfoRequestBatch.find(params[:id])
  end

  def check_info_request_batch
    return if can? :admin, @info_request_batch

    raise ActiveRecord::RecordNotFound
  end
end
