##
# Job to apply masks and censor rules to FoiAttachment objects. Masked file will
# be stored as FoiAttachment#file ActiveStorage association.
#
# Example:
#   FoiAttachment::MaskJob.perform(FoiAttachment.first)
#
class FoiAttachment::MaskJob < ApplicationJob
  queue_as :default
  unique :until_executed, on_conflict: :log

  attr_reader :attachment

  delegate :incoming_message, to: :attachment
  delegate :info_request, to: :incoming_message

  def perform(attachment)
    @attachment = attachment
    mask

  rescue FoiAttachment::MissingError
    incoming_message.parse_raw_email!

    begin
      attachment.reload
    rescue ActiveRecord::RecordNotFound
      @attachment = attachment.load_attachment_from_incoming_message
    end

    mask if @attachment
  end

  private

  def mask
    attachment.mask

    # Masking hit a Regexp::TimeoutError. Notify once (on the first failure) so
    # it can be investigated, then stop.
    if attachment.masking_failed?
      notify_masking_failure if attachment.masking_failed_at_previously_changed?
      return
    end

    # ensure the after_commit callback runs which uploads the blob, without this
    # the callback might not execute in time and the job exits resulting in the
    # lost of the masked attachment body.
    return if attachment.file_blob.service.exist?(attachment.file_blob.key)

    attachment.run_callbacks(:commit)
  end

  def notify_masking_failure
    return unless send_exception_notifications?

    ExceptionNotifier.notify_exception(
      Regexp::TimeoutError.new("masking timed out (ID=#{attachment.id})"),
      data: { foi_attachment: attachment.id }
    )
  end
end
