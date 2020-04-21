##
# This module contains shared methods for InfoRequest classification
#
module Classifiable
  extend ActiveSupport::Concern

  included do
    before_action :find_info_request, :authorise_info_request
    before_action :ensure_message, if: :message_required_for_state?,
                                   only: :create

    # rubocop:disable Style/ClassVars, Lint/HandleExceptions
    @@custom_states_loaded = false
    begin
      require 'customstates'
      include RequestControllerCustomStates
      @@custom_states_loaded = true
    rescue LoadError, NameError
    end
    # rubocop:enable Style/ClassVars, Lint/HandleExceptions
  end

  def message
    @described_state = params[:described_state]
    @last_info_request_event_id = @info_request.
      last_event_id_needing_description
    @title = case @described_state
             when 'error_message'
               _("I've received an error message")
             when 'requires_admin'
               _('This request requires administrator attention')
             else
               raise 'Unsupported state'
             end

    render 'classifications/message'
  end

  private

  def find_info_request
    raise NotImplementedError
  end

  def authorise_info_request
    raise NotImplementedError
  end

  def redirect_to_info_request
    raise NotImplementedError
  end

  def classification_params
    params.require(:classification).permit(:described_state, :message)
  end

  def ensure_message
    return if classification_params[:message] || !message_required_for_state?

    redirect_to url_for(
      action: :message,
      url_title: @info_request.url_title,
      described_state: classification_params[:described_state]
    )
  end

  def message_required_for_state?
    %w[error_message requires_admin].include?(
      classification_params[:described_state]
    )
  end
end
