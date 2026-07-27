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

  def masking_failed?
    masking_failed_at.present?
  end

  def mask
    return if masking_failed?

    body = apply_masks(unmasked_body, content_type)

    if content_type == 'text/html'
      body =
        Loofah.html5_document(body) { |c| c[:max_tree_depth] = 800 }.
        scrub!(:prune).
        to_html(encoding: 'UTF-8')
    end

    update(body: body, masked_at: Time.zone.now)

  rescue Regexp::TimeoutError
    update(masking_failed_at: Time.zone.now) if persisted?
  end

  def mask_later
    FoiAttachment::MaskJob.perform_later(self)
  end

  def mask_siblings
    incoming_message.foi_attachments.each do |sibling|
      next if sibling == self
      next if sibling.masked? || sibling.erased?

      sibling.mask
    end
  end
end
