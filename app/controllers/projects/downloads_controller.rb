##
# Controller which manages Project data downloads.
#
class Projects::DownloadsController < Projects::BaseController
  skip_before_action :html_response

  def show
    authorize! :download, @project

    respond_to do |format|
      format.csv do
        export = Project::Export.new(@project)
        send_data export.to_csv, filename: export.name, type: 'text/csv'
      end
    end
  end
end
