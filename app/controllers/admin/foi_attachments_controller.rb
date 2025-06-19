##
# Controller to manage FoiAttachment instances
#
class Admin::FoiAttachmentsController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def edit
  end

  def update
    if @foi_attachment.update_and_log_event(
        **foi_attachment_params,
        event: { editor: admin_current_user }
      )
      @foi_attachment.expire

      if @foi_attachment.locked? && !@foi_attachment.masked?
        flash[:notice] = <<~TXT.squish
          Attachment successfully updated and locked. Please wait for masking to
          complete before adding additional censor rules.
        TXT
      else
        flash[:notice] = 'Attachment successfully updated.'
      end
      redirect_to edit_admin_incoming_message_path(@incoming_message)

    else
      flash.now[:error] = @foi_attachment.errors.full_messages.to_sentence
      render action: 'edit'
    end
  end

  private

  def foi_attachment_params
    params.require(:foi_attachment).permit(
      :locked,
      :replacement_body, :replacement_file,
      :replaced_filename, :replaced_reason,
      :prominence, :prominence_reason
    )
  end

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
