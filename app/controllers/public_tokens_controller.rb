##
# Controller responsible for creating, destroying public tokens and rendering
# any InfoRequest by its public token
#
class PublicTokensController < ApplicationController
  before_action :find_info_request, only: %i[create destroy]

  before_action :find_info_request_by_public_token, only: :show
  before_action :can_view_info_request, only: :show

  def show
    render plain: 'Success'
  end

  def create
    redirect_to show_request_path(@info_request.url_title)
  end

  def destroy
    redirect_to show_request_path(@info_request.url_title)
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(url_title: params[:url_title])
  end

  def find_info_request_by_public_token
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
end
