##
# Controller to erase OutgoingMessage instances
#
class Admin::OutgoingMessages::ErasuresController < AdminController
  before_action :set_outgoing_message, :set_info_request
  before_action :check_info_request

  # erase the OutgoingMessage inline as it is a single db query
  def create
    @outgoing_message.erase!(editor: admin_current_user, reason: erasure_reason)
    @outgoing_message.expire
    flash[:notice] = 'Outgoing message successfully erased.'
    redirect_to admin_request_url(@outgoing_message.info_request)
  end

  private

  def erasure_reason
    erasure_params[:erasure_reason].presence ||
      raise(ActionController::ParameterMissing, :erasure_reason)
  end

  def erasure_params
    params.require(:outgoing_message).permit(:erasure_reason)
  end

  def set_outgoing_message
    @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
  end

  def set_info_request
    @info_request = @outgoing_message.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
