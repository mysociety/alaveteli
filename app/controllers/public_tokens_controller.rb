##
# Controller responsible for rendering any InfoRequest by its public token
#
class PublicTokensController < ApplicationController
  before_action :find_info_request, :can_view_info_request

  def show
    respond_to do |format|
      format.html { render plain: 'Success' }
    end
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(public_token: params[:id])
  end

  def can_view_info_request
    if guest.can?(:read, @info_request)
      redirect_to show_request_path(@info_request.url_title)
    elsif cannot?(:read, @info_request)
      render_hidden
    end
  end

  def guest
    @guest ||= Ability.new(nil)
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, public_token: true)
  end
end
