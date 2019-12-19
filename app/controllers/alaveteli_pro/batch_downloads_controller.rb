##
# Controller which manages Alaveteli Professional info request batch data
# downloads.
#
class AlaveteliPro::BatchDownloadsController < AlaveteliPro::BaseController
  def show
    authorize! :download, info_request_batch

    respond_to do |format|
      format.html { head :bad_request }
      format.csv do
        metrics = InfoRequestBatchMetrics.new(info_request_batch)
        send_data metrics.to_csv, filename: metrics.name, type: 'text/csv'
      end
    end
  end

  private

  def info_request_batch
    @info_request_batch ||= current_user.info_request_batches.
      find(params[:info_request_batch_id])
  end
end
