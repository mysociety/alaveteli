##
# Job to apply masks and censor rules to FoiAttachment objects. Masked file will
# be stored as FoiAttachment#file ActiveStorage association.
#
# Example:
#   FoiAttachmentMaskJob.perform(FoiAttachment.first)
#
class FoiAttachmentMaskJob < ApplicationJob
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

    mask
  end

  private

  def mask
    body = AlaveteliTextMasker.apply_masks(
      attachment.unmasked_body,
      attachment.content_type,
      masks
    )

    if attachment.content_type == 'text/html'
      body =
        Loofah.scrub_document(body, :prune).
        to_html(encoding: 'UTF-8').
        try(:html_safe)
    end

    attachment.update(body: body, masked_at: Time.zone.now)
  end

  def masks
    {
      censor_rules: info_request.applicable_censor_rules,
      masks: info_request.masks
    }
  end
end
