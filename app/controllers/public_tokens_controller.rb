##
# Controller responsible for rendering any InfoRequest by its public token
#
class PublicTokensController < ApplicationController
  include PublicTokenable

  before_action :find_info_request, :can_view_info_request
  before_action :assign_variables_for_show_template

  def show
    headers['X-Robots-Tag'] = 'noindex'

    respond_to do |format|
      format.html { render template: 'request/show' }
    end
  end

  private

  def find_info_request
    @info_request = InfoRequest.find_by!(public_token: public_token)
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

  # rubocop:disable all
  def assign_variables_for_show_template
    # taken from RequestController#assign_variables_for_show_template

    @show_profile_photo = !!(
      !@info_request.is_external? &&
      @info_request.user.show_profile_photo? &&
      !@render_to_file
    )

    @old_unclassified =
      @info_request.is_old_unclassified? && !authenticated_user.nil?
    @is_owning_user = @info_request.is_owning_user?(authenticated_user)
    @new_responses_count =
      @info_request.
      events_needing_description.
      select { |event| event.event_type == 'response' }.
      size
  end
  # rubocop:enable all
end
