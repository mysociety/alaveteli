##
# Job to apply masks and censor rules to FoiAttachment objects. Masked file will
# be stored as FoiAttachment#file ActiveStorage association.
#
# Example:
#   FoiAttachmentMaskJob.perform(FoiAttachment.first)
#
class FoiAttachmentMaskJob < ApplicationJob
  include ActionView::Helpers::SanitizeHelper

  queue_as :default
  unique :until_and_while_executing, on_conflict: :log

  attr_reader :attachment

  delegate :incoming_message, to: :attachment
  delegate :info_request, to: :incoming_message

  def perform(attachment)
    @attachment = attachment
    mask

  rescue FoiAttachment::MissingAttachment
    incoming_message.parse_raw_email!(true)

    begin
      attachment.reload
    rescue ActiveRecord::RecordNotFound
      @attachment = attachment.load_attachment_from_incoming_message
    end

    mask if @attachment
  end

  private

  def mask
    body = AlaveteliTextMasker.apply_masks(
      attachment.unmasked_body,
      attachment.content_type,
      masks
    )

    if attachment.content_type == 'text/html'
      script_scrubber = Rails::HTML::TargetScrubber.new(prune: true)
      script_scrubber.tags = ['script']

      body = sanitize(body, scrubber: script_scrubber)
      body = sanitize(body) # HTML5 scrubber
    end

    attachment.update(body: body, masked_at: Time.zone.now)

    # ensure the after_commit callback runs which uploads the blob, without this
    # the callback might not execute in time and the job exits resulting in the
    # lost of the masked attachment body.
    return if attachment.file_blob.service.exist?(attachment.file_blob.key)

    attachment.run_callbacks(:commit)
  end

  def masks
    {
      censor_rules: info_request.applicable_censor_rules,
      masks: info_request.masks
    }
  end
end
