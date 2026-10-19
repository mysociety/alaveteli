# Allow admins to change the prominence of an IncomingMessage
class Admin::IncomingMessages::ProminenceController < AdminController
  before_action :set_incoming_message, :set_info_request
  before_action :check_info_request

  def update
    if @incoming_message.update_and_log_event(
      **prominence_params,
      event: { editor: admin_current_user }
    )

      @incoming_message.expire

      flash[:notice] = 'Prominence updated.'
    else
      flash[:error] = @incoming_message.errors.full_messages.to_sentence
    end

    redirect_to edit_admin_incoming_message_path(@incoming_message)
  end

  private

  def prominence_params
    { prominence: incoming_message_params[:prominence],
      prominence_reason: incoming_message_params[:prominence_reason] }
  end

  def incoming_message_params
    params.require(:incoming_message).permit(:prominence, :prominence_reason)
  end

  def set_incoming_message
    @incoming_message = IncomingMessage.find(params[:incoming_message_id])
  end

  def set_info_request
    @info_request = @incoming_message&.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
