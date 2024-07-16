##
# Controller which manages Project data downloads.
#
class Projects::DatasetController < Projects::BaseController
  skip_before_action :html_response

  before_action :load_dataset_key_set

  def show
    authorize! :view, @dataset_key_set

    respond_to do |format|
      format.csv do
        export = Project::Export.new(@project)
        send_data export.to_csv, filename: export.name, type: 'text/csv'
      end
    end
  end

  private

  def load_dataset_key_set
    @dataset_key_set = @project.key_set
  end
end
