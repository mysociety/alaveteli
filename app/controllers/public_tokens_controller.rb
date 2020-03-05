##
# Controller responsible for rendering any InfoRequest by its public token
#
class PublicTokensController < ApplicationController
  before_action :find_info_request, :can_view_info_request

  def show
    @public_token_view = true

    headers['X-Robots-Tag'] = 'noindex'

    respond_to do |format|
      format.html { render template: 'request/show' }
    end
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(public_token: params[:id])
  end

  def can_view_info_request
    render_hidden if cannot?(:read, @info_request)
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, public_token: true)
  end
end
