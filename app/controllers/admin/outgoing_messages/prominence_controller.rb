# Allow admins to change the prominence of an OugoingMessage
class Admin::OutgoingMessages::ProminenceController < AdminController
  before_action :set_outgoing_message, :set_info_request
  before_action :check_info_request

  def update
    if @outgoing_message.update_and_log_event(
      **prominence_params,
      event: { editor: admin_current_user }
    )

      @outgoing_message.expire

      flash[:notice] = 'Prominence updated.'
    else
      flash[:error] = @outgoing_message.errors.full_messages.to_sentence
    end

    redirect_to edit_admin_outgoing_message_path(@outgoing_message)
  end

  private

  def prominence_params
    { prominence: outgoing_message_params[:prominence],
      prominence_reason: outgoing_message_params[:prominence_reason] }
  end

  def outgoing_message_params
    params.require(:outgoing_message).permit(:prominence, :prominence_reason)
  end

  def set_outgoing_message
    @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
  end

  def set_info_request
    @info_request = @outgoing_message&.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
