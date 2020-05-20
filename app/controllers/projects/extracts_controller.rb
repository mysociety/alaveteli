# Extract data from a Project
class Projects::ExtractsController < Projects::BaseController
  before_action :authenticate, :find_info_request

  def show
    authorize! :read, @project
  end

  def create
    authorize! :read, @project

    if @project.submissions.create(submission_params)
      redirect_to project_extract_path
    else
      render :show
    end
  end

  private

  def authenticate
    authenticated?(
      web: _('To join this project'),
      email: _('Then you can join this project'),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: site_name)
    )
  end

  def find_info_request
    if params[:url_title]
      @info_request = @project.info_requests.find_by!(
        url_title: params[:url_title]
      )
    else
      # HACK: Temporarily just find a random request to render
      @info_request = @project.info_requests.sample
    end
  end

  def extract_params
    params.require(:extract).permit(
      :dataset_key_set_id, values_attributes: [:dataset_key_id, :value]
    ).merge(
      resource: @info_request
    )
  end

  def submission_params
    {
      user: current_user,
      info_request: @info_request,
      resource: Dataset::ValueSet.new(extract_params)
    }
  end
end
