##
# Controller to erase IncomingMessage instances
#
class Admin::IncomingMessages::ErasuresController < AdminController
  before_action :set_incoming_message, :set_info_request
  before_action :check_info_request

  def create
    @incoming_message.erase_later(
      editor: admin_current_user,
      reason: erasure_reason
    )

    @incoming_message.expire

    flash[:notice] = 'Incoming message erasure has been queued.'
    redirect_to admin_request_url(@incoming_message.info_request)
  end

  private

  def erasure_reason
    erasure_params[:erasure_reason].presence ||
      raise(ActionController::ParameterMissing, :erasure_reason)
  end

  def erasure_params
    params.require(:incoming_message).permit(:erasure_reason)
  end

  def set_incoming_message
    @incoming_message = IncomingMessage.find(params[:incoming_message_id])
  end

  def set_info_request
    @info_request = @incoming_message.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
