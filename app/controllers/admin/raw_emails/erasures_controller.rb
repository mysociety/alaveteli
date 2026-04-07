# Allow admins to erase RawEmail records.
class Admin::RawEmails::ErasuresController < AdminController
  rescue_from RawEmail::ErasedError, with: :already_erased
  rescue_from RawEmail::UnmaskedAttachmentsError, with: :unmasked_attachments

  before_action :set_raw_email

  def create
    if @raw_email.erase(editor: admin_current_user, reason: erasure_reason)
      redirect_to admin_raw_email_path(@raw_email), notice: success_message
    else
      redirect_to admin_raw_email_path(@raw_email), error: failure_message
    end
  end

  private

  def set_raw_email
    @raw_email = RawEmail.find(params[:raw_email_id])
  end

  def erasure_reason
    params.require(:raw_email).require(:erasure_reason)
  end

  def success_message
    'This RawEmail has been erased. All attachments have been locked.'
  end

  def failure_message
    'Could not erase this RawEmail. Request technical assistance.'
  end

  def already_erased
    msg = 'This RawEmail has already been erased.'
    redirect_to admin_raw_email_path(@raw_email), error: msg
  end

  def unmasked_attachments
    msg = 'Ensure all attachments are masked before attempting to erase.'
    redirect_to admin_raw_email_path(@raw_email), error: msg
  end
end
