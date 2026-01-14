# Allow admins to lock and unlock an FoiAttachment.
class Admin::FoiAttachments::LocksController < AdminController
  before_action :set_foi_attachment, :set_info_request
  before_action :check_info_request

  def create
    if @foi_attachment.lock(editor: admin_current_user, reason: lock_reason)
      redirect_to edit_admin_foi_attachment_path(@foi_attachment),
                  notice: lock_success_message
    else
      redirect_to edit_admin_foi_attachment_path(@foi_attachment),
                  error: @foi_attachment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @foi_attachment. errors.add(:base, 'This attachment cannot be unlocked.')

    if @foi_attachment.unlock(editor: admin_current_user, reason: lock_reason)
      redirect_to edit_admin_foi_attachment_path(@foi_attachment),
                  notice: 'Attachment unlocked.'
    else
      redirect_to edit_admin_foi_attachment_path(@foi_attachment),
                  error: @foi_attachment.errors.full_messages.to_sentence
    end
  end

  private

  def lock_success_message
    if @foi_attachment.locked? && !@foi_attachment.masked?
      <<~TXT.squish
        Attachment successfully locked. Please wait for masking to
        complete before adding additional censor rules.
      TXT
    else
      'Attachment successfully locked.'
    end
  end

  def lock_reason
    foi_attachment_params[:lock_reason].presence ||
      raise(ActionController::ParameterMissing, :lock_reason)
  end

  def foi_attachment_params
    params.require(:foi_attachment).permit(:lock_reason)
  end

  def set_foi_attachment
    @foi_attachment = FoiAttachment.find(params[:foi_attachment_id])
  end

  def set_info_request
    @info_request = @foi_attachment&.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
