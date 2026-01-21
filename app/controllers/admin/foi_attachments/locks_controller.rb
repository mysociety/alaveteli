# Allow admins lock and unlock FoiAttachment records.
class Admin::FoiAttachments::LocksController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def create
    @foi_attachment.lock!(editor: admin_current_user, reason: reason) &&
      @foi_attachment.expire

    flash[:notice] = if @foi_attachment.locked? && !@foi_attachment.masked?
      <<~TXT.squish
        Attachment locked. Please wait for masking to complete before adding
        additional censor rules.
      TXT
    else
      'Attachment locked.'
    end

    redirect_to edit_admin_foi_attachment_path(@foi_attachment)
  end

  def destroy
    if @foi_attachment.unlock!(editor: admin_current_user, reason: reason)
      @foi_attachment.expire

      flash[:notice] = 'Attachment unlocked.'
    else
      flash[:error] = @foi_attachment.errors.full_messages.to_sentence
    end

    redirect_to edit_admin_foi_attachment_path(@foi_attachment)
  end

  private

  def reason
    params[:reason]
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
