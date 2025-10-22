##
# Controller responsible for handling Alaveteli Pro InfoRequest classification
#
class AlaveteliPro::ClassificationsController < AlaveteliPro::BaseController
  include Classifiable

  skip_before_action :pro_user_authenticated?

  def create
    set_described_state

    flash[:notice] = _('Your request has been updated!')
    redirect_to show_request_path(
      url_title: info_request.url_title
    )
  end

  private

  def info_request
    @info_request ||= InfoRequest.find_by!(url_title: params[:url_title])
  end
end
