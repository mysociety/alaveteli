##
# Controller which manages viewing and downloading Project datasets.
#
class Projects::DatasetController < Projects::BaseController
  skip_before_action :html_response

  before_action :authenticate
  before_action :load_dataset_key_set, only: :show

  def show
    authorize! :view, @dataset_key_set
    @export = Project::Export.new(@project)

    respond_to do |format|
      format.html
      format.csv do
        send_data @export.to_csv, filename: @export.name, type: 'text/csv'
      end
    end
  end

  def edit
    authorize! :edit, @project
  end

  def update
    authorize! :edit, @project

    if @project.update(project_dataset_params)
      redirect_to project_dataset_path(@project),
        notice: _('Dataset was successfully updated.')
    else
      render :edit
    end
  end

  private

  def authenticate
    authenticated? || ask_to_login(web: _('To view this project'))
  end

  def load_dataset_key_set
    @dataset_key_set = @project.key_set
  end

  def project_dataset_params
    params.require(:project).permit(:dataset_description, :dataset_public)
  end
end
