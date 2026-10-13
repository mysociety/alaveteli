##
# Controller which manages Alaveteli Professional info request batch data
# downloads.
#
class AlaveteliPro::BatchDownloadsController < AlaveteliPro::BaseController
  include ActionController::Live

  skip_before_action :html_response
  skip_before_action :pro_user_authenticated?
  before_action :user_authenticated?

  def show
    authorize! :download, info_request_batch

    respond_to do |format|
      format.zip { download_zip }
      format.csv do
        metrics = InfoRequestBatchMetrics.new(info_request_batch)
        send_data metrics.to_csv, filename: metrics.name, type: 'text/csv'
      end
    end
  end

  private

  def user_authenticated?
    return if authenticated?

    ask_to_login(
      web: _('To download batch requests'),
      email: _('Then you can download batch requests')
    )
  end

  def info_request_batch
    @info_request_batch ||= InfoRequestBatch.
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
