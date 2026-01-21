# Allow admins lock and unlock FoiAttachment records.
class Admin::FoiAttachments::LocksController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def create
    if @foi_attachment.update_and_log_event(
        locked: true,
        event: { editor: admin_current_user }
      )
      @foi_attachment.expire

      if @foi_attachment.locked? && !@foi_attachment.masked?
        flash[:notice] = <<~TXT.squish
          Attachment locked. Please wait for masking to complete before adding
          additional censor rules.
        TXT
      else
        flash[:notice] = 'Attachment locked.'
      end

      redirect_to edit_admin_foi_attachment_path(@foi_attachment)
    else
      flash.now[:error] = @foi_attachment.errors.full_messages.to_sentence
      render 'admin/foi_attachments/edit'
    end
  end

  def destroy
    if @foi_attachment.update_and_log_event(
        locked: false,
        event: { editor: admin_current_user }
      )
      @foi_attachment.expire

      redirect_to edit_admin_foi_attachment_path(@foi_attachment),
                  notice: 'Attachment unlocked.'
    else
      flash.now[:error] = @foi_attachment.errors.full_messages.to_sentence
      render 'admin/foi_attachments/edit'
    end
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
