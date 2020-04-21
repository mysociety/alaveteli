##
# Controller responsible for handling base InfoRequest classification
#
class ClassificationsController < ApplicationController
  include Classifiable

  prepend_before_action :check_read_only, only: :create

  rescue_from CanCan::AccessDenied do
    authenticated_as_user?(
      @info_request.user,
      web: _('To classify the response to this FOI request'),
      email: _('Then you can classify the FOI response you have got from ' \
               '{{authority_name}}.',
               authority_name: @info_request.public_body.name),
      email_subject: _('Classify an FOI response from {{authority_name}}',
                       authority_name: @info_request.public_body.name)
    )
  end

  rescue_from ActionController::ParameterMissing do
    flash[:error] = _('Please choose whether or not you got some of the ' \
                      'information that you wanted.')
    redirect_to_info_request
  end

  def create
    set_last_request(@info_request)

    if params[:last_info_request_event_id].to_i != @info_request.
        last_event_id_needing_description
      flash[:error] = _('The request has been updated since you originally ' \
                        'loaded this page. Please check for any new incoming ' \
                        'messages below, and try again.')
      redirect_to_info_request
      return
    end

    set_described_state

    # If you're not the *actual* requester. e.g. you are playing the
    # classification game, or you're doing this just because you are an
    # admin user (not because you also own the request).
    unless @info_request.is_actual_owning_user?(current_user)
      # Create a classification event for league tables
      RequestClassification.create!(
        user_id: current_user.id,
        info_request_event_id: @status_update_event.id
      )

      # Don't give advice on what to do next, as it isn't their request
      if session[:request_game]
        flash[:notice] = { partial: 'request_game/thank_you.html.erb',
                           locals: {
                             info_request_title: @info_request.title,
                             url: request_path(@info_request)
                           } }
        redirect_to categorise_play_url
      else
        flash[:notice] = _('Thank you for updating this request!')
        redirect_to_info_request
      end
      return
    end

    # Display advice for requester on what to do next, as appropriate
    calculated_status = @info_request.calculate_status
    partial_path = 'request/describe_notices'
    if template_exists?(calculated_status, [partial_path], true)
      flash[:notice] =
        {
          partial: "#{partial_path}/#{calculated_status}",
          locals: {
            info_request_id: @info_request.id,
            annotations_enabled: feature_enabled?(:annotations)
          }
        }
    end

    case calculated_status
    when 'waiting_response', 'waiting_response_overdue', 'not_held',
      'successful', 'internal_review', 'error_message', 'requires_admin'
      redirect_to_info_request
    when 'waiting_response_very_overdue', 'rejected', 'partially_successful'
      redirect_to unhappy_url(@info_request)
    when 'waiting_clarification', 'user_withdrawn'
      redirect_to respond_to_last_url(@info_request)
    when 'gone_postal'
      redirect_to respond_to_last_url(@info_request) + '?gone_postal=1'
    else
      return theme_describe_state(@info_request) if @@custom_states_loaded

      raise "unknown calculate_status #{@info_request.calculate_status}"
    end
  end

  private

  def find_info_request
    @info_request = InfoRequest.not_embargoed.find_by!(
      url_title: params[:url_title]
    )
  end

  def authorise_info_request
    # If this is an external request, go to the request page - we don't allow
    # state change from the front end interface.
    if @info_request.is_external?
      redirect_to_info_request
    else
      authorize! :update_request_state, @info_request
    end
  end

  def redirect_to_info_request
    redirect_to request_path(@info_request)
  end
end
