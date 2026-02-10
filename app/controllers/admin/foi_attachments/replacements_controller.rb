# Allow admins to upload replacement data for an FoiAttachment.
class Admin::FoiAttachments::ReplacementsController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def create
    @foi_attachment.replace(
      **foi_attachment_params.to_h.symbolize_keys,
      editor: admin_current_user,
      reason: reason
    )

    flash[:notice] = if @foi_attachment.locked? && !@foi_attachment.masked?
      <<~TXT.squish
        Attachment successfully updated and locked. Please wait for masking to
        complete before adding additional censor rules.
      TXT
    else
      'Attachment successfully updated.'
    end

    redirect_to edit_admin_foi_attachment_path(@foi_attachment)
  end

  def destroy
    @foi_attachment.clear_replacement(
      editor: admin_current_user,
      reason: reason
    )

    redirect_to edit_admin_foi_attachment_path(@foi_attachment),
                notice: 'Replacement cleared.'
  end

  private

  def reason
    params[:reason]
  end

  def foi_attachment_params
    params.require(:foi_attachment).permit(
      :replacement_body, :replacement_file,
      :replaced_filename
    )
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

