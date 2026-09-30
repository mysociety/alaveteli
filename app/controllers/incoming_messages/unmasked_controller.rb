# Shows the requester the main body of a response without masks applied. This
# is loaded on demand as the text has to be pulled from the raw email.
class IncomingMessages::UnmaskedController < ApplicationController
  before_action :set_incoming_message, :authorize_incoming_message

  def show
    no_store

    @info_request = @incoming_message.info_request
    @body = @incoming_message.get_unmasked_body_for_html_display

    if request.xhr?
      render partial: 'unmasked_body'
    else
      render :show
    end
  end

  private

  def set_incoming_message
    @incoming_message = IncomingMessage.find(params[:incoming_message_id])
  end

  def authorize_incoming_message
    authorize! :read_unmasked_body, @incoming_message
  end
end
