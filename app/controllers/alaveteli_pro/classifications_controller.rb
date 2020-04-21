##
# Controller responsible for handling Alaveteli Pro InfoRequest classification
#
class AlaveteliPro::ClassificationsController < AlaveteliPro::BaseController
  include Classifiable

  def create
    @info_request = InfoRequest.find_by!(url_title: params[:url_title])
    authorize! :update_request_state, @info_request
    new_status = info_request_params[:described_state]
    @info_request.set_described_state(new_status, current_user)
    flash[:notice] = _('Your request has been updated!')
    redirect_to show_alaveteli_pro_request_path(
      url_title: @info_request.url_title
    )
  end

  private

  def info_request_params
    params.require(:info_request).permit(:described_state)
  end
end
