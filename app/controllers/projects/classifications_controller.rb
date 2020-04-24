##
# Controller responsible for handling project InfoRequest classification
#
# Requires `url_title` to be passed in as a param
#
class Projects::ClassificationsController < Projects::BaseController
  include Classifiable

  def create
    set_described_state

    flash[:notice] = _('Thank you for updating this request!')
    redirect_to project_path(@project)
  end

  private

  def find_info_request
    @info_request = @project.info_requests.find_by!(
      url_title: params[:url_title]
    )
  end

  def authorise_info_request
    authorize! :update_request_state, @info_request
  end
end
