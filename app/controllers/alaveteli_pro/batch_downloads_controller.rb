##
# Controller which manages Alaveteli Professional info request batch data
# downloads.
#
class AlaveteliPro::BatchDownloadsController < AlaveteliPro::BaseController
  include ActionController::Live

  def show
    authorize! :download, info_request_batch

    respond_to do |format|
      format.html { head :bad_request }
      format.zip { download_zip }
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

  def download_zip
    zip = InfoRequestBatchZip.new(info_request_batch, ability: current_ability)
    send_file_headers!(
      type: 'application/zip',
      disposition: 'attachment',
      filename: zip.name
    )
    response.headers['Last-Modified'] = Time.zone.now.httpdate.to_s
    response.headers['X-Accel-Buffering'] = 'no'

    zip.stream do |chunk|
      response.stream.write(chunk)
    end
  ensure
    response.stream.close
  end
end
