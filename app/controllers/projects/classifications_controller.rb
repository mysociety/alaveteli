##
# Controller responsible for handling project InfoRequest classification
#
# Requires `url_title` to be passed in as a param
#
class Projects::ClassificationsController < Projects::BaseController
  include Classifiable

  def create
    @project.submissions.create(**submission_params)

    flash[:notice] = _('Thank you for updating this request!')
    redirect_to project_classify_path(@project)
  end

  private

  def find_info_request
    @info_request = @project.info_requests.classifiable.find_by!(
      url_title: url_title
    )
  end

  def authorise_info_request
    authorize! :update_request_state, @info_request
  end

  def url_title
    params.require(:url_title)
  end

  def submission_params
    {
      user: current_user,
      info_request: @info_request,
      resource: set_described_state(project: @project)
    }
  end
end
