# Handles the masking of FoiAttachment records. Masking is the process of
# applying TextMask and CensorRule redactions.
module FoiAttachment::Maskable
  extend ActiveSupport::Concern

  def masked?
    file.attached? && masked_at.present? && masked_at < Time.zone.now
  end
end
