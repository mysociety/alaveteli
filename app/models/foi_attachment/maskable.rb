# Handles the masking of FoiAttachment records. Masking is the process of
# applying TextMask and CensorRule redactions.
module FoiAttachment::Maskable
  extend ActiveSupport::Concern

  def masked?
    file.attached? && masked_at.present? && masked_at < Time.zone.now
  end

  def mask
    body = apply_masks(unmasked_body, content_type)

    if content_type == 'text/html'
      body =
        Loofah.scrub_document(body, :prune).
        to_html(encoding: 'UTF-8').
        try(:html_safe)
    end

    update(body: body, masked_at: Time.zone.now)
  end

  def mask_later
    FoiAttachment::MaskJob.perform_later(self)
  end

  def apply_masks(text, content_type)
    AlaveteliTextMasker.apply_masks(text, content_type, masks)
  end

  private

  def masks
    {
      censor_rules: info_request.applicable_censor_rules,
      masks: info_request.masks
    }
  end
end
