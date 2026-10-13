##
# Controller to erase FoiAttachment instances
#
class Admin::FoiAttachments::ErasuresController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def create
    @foi_attachment.erase_later(
      editor: admin_current_user, reason: erasure_reason
    )
    flash[:notice] = 'Attachment erasure has been queued.'
    redirect_to edit_admin_foi_attachment_path(@foi_attachment)
  end

  private

  def erasure_reason
    erasure_params[:erasure_reason].presence ||
      raise(ActionController::ParameterMissing, :erasure_reason)
  end

  def erasure_params
    params.require(:foi_attachment).permit(:erasure_reason)
  end

  def set_foi_attachment
    @foi_attachment = FoiAttachment.find(params[:foi_attachment_id])
  end

  def set_incoming_message
    @incoming_message = @foi_attachment&.incoming_message
  end

  def set_info_request
    @info_request = @incoming_message&.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
