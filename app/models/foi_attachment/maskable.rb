# Handles the masking of FoiAttachment records. Masking is the process of
# applying TextMask and CensorRule redactions.
module FoiAttachment::Maskable
  extend ActiveSupport::Concern
  include ActionView::Helpers::SanitizeHelper

  def masked?
    file.attached? && masked_at.present? && masked_at < Time.zone.now
  end

  def mask
    body = AlaveteliTextMasker.apply_masks(
      unmasked_body,
      content_type,
      masks
    )

    if content_type == 'text/html'
      script_scrubber = Rails::HTML::TargetScrubber.new(prune: true)
      script_scrubber.tags = ['script']

      body = sanitize(body, scrubber: script_scrubber)
      body = sanitize(body) # HTML5 scrubber
    end

    update(body: body, masked_at: Time.zone.now)
  end

  def mask_later
    FoiAttachmentMaskJob.perform_later(self)
  end

  private

  def masks
    {
      censor_rules: info_request.applicable_censor_rules,
      masks: info_request.masks
    }
  end
end
