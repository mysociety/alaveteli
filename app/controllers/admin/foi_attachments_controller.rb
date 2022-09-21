##
# Controller to manage FoiAttachment instances
#
class Admin::FoiAttachmentsController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def edit
  end

  def update
    redirect_to edit_admin_incoming_message_path(@incoming_message)
  end

  private

  def set_foi_attachment
    @foi_attachment = FoiAttachment.find(params[:id])
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
