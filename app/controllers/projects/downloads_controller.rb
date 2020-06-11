##
# Controller which manages Project data downloads.
#
class Projects::DownloadsController < Projects::BaseController
  def show
    authorize! :download, @project

    respond_to do |format|
      format.html { head :bad_request }
      format.csv do
        send_data 'CSV_DATA', type: 'text/csv'
      end
    end
  end
end
