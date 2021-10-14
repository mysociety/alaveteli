##
# Controller responsible for creating, destroying public tokens and rendering
# any InfoRequest by its public token
#
class PublicTokensController < ApplicationController
  before_action :find_info_request, only: %i[create destroy]
  before_action :can_share_info_request, only: %i[create destroy]

  before_action :find_info_request_by_public_token, only: :show
  before_action :can_view_info_request, only: :show

  def show
    render plain: 'Success'
  end

  def create
    @info_request.enable_public_token!

    public_url = public_token_url(@info_request.public_token, locale: false)
    anchor = helpers.link_to(public_url, public_url, target: '_blank')

    flash.notice = {
      inline: _('This request is now publicly accessible via {{public_url}}',
                public_url: anchor)
    }

    redirect_to show_request_path(@info_request.url_title)
  end

  def destroy
    @info_request.disable_public_token!

    flash.notice = _('The publicly accessible link for this request has now ' \
                     'been disabled')

    redirect_to show_request_path(@info_request.url_title)
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(url_title: params[:url_title])
  end

  def can_share_info_request
    authorize! :share, @info_request
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
