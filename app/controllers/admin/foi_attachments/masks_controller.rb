# Allow admins to force the masking of FoiAttachment records.
class Admin::FoiAttachments::MasksController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def create
    @foi_attachment.mask_later
    redirect_to edit_admin_foi_attachment_path(@foi_attachment),
                notice: 'Masking queued.'
  end

  private

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

