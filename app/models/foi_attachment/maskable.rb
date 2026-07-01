# Handles the masking of FoiAttachment records. Masking is the process of
# applying TextMask and CensorRule redactions.
module FoiAttachment::Maskable
  extend ActiveSupport::Concern

  included do
    delegate :apply_masks, to: :info_request
  end

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
end
