##
# Controller responsible for handling Alaveteli Pro InfoRequest classification
#
class AlaveteliPro::ClassificationsController < AlaveteliPro::BaseController
  include Classifiable

  def create
    described_state = classification_params[:described_state]
    message = classification_params[:message]

    @info_request.set_described_state(described_state, current_user, message)

    flash[:notice] = _('Your request has been updated!')
    redirect_to_info_request
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(url_title: params[:url_title])
  end

  def authorise_info_request
    authorize! :update_request_state, @info_request
  end

  def redirect_to_info_request
    redirect_to show_alaveteli_pro_request_path(
      url_title: @info_request.url_title
    )
  end
end
