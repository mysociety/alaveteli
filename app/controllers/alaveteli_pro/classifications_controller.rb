##
# Controller responsible for handling Alaveteli Pro InfoRequest classification
#
class AlaveteliPro::ClassificationsController < AlaveteliPro::BaseController
  include Classifiable

  def create
    set_described_state

    flash[:notice] = _('Your request has been updated!')
    redirect_to show_alaveteli_pro_request_path(
      url_title: @info_request.url_title
    )
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(url_title: params[:url_title])
  end

  def authorise_info_request
    authorize! :update_request_state, @info_request
  end
end
