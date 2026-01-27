# Allow admins to change the prominence of an FoiAttachment
class Admin::FoiAttachments::ProminenceController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def update
    if @foi_attachment.update_and_log_event(
        **prominence_params,
        event: { editor: admin_current_user }
      )

      @foi_attachment.expire

      flash[:notice] = 'Prominence updated.'
    else
      flash[:error] = @foi_attachment.errors.full_messages.to_sentence
    end

    redirect_to edit_admin_foi_attachment_path(@foi_attachment)
  end

  private

  def prominence_params
    { prominence: foi_attachment_params[:prominence],
      prominence_reason: foi_attachment_params[:prominence_reason] }
  end

  def foi_attachment_params
    params.require(:foi_attachment).permit(:prominence, :prominence_reason)
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
