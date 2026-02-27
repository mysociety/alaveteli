# Handles the masking of FoiAttachment records. Masking is the process of
# applying TextMask and CensorRule redactions.
module FoiAttachment::Maskable
  extend ActiveSupport::Concern

  def masked?
    file.attached? && masked_at.present? && masked_at < Time.zone.now
  end

  def mask
    if content_type == 'application/pdf'
      mask_pdf
    else
      mask_default
    end
  end

  def mask_later
    FoiAttachmentMaskJob.perform_later(self)
  end

  private

  def mask_default
    body = AlaveteliTextMasker.apply_masks(
      unmasked_body,
      content_type,
      masks
    )

    if content_type == 'text/html'
      body =
        Loofah.scrub_document(body, :prune).
        to_html(encoding: 'UTF-8').
        try(:html_safe)
    end

    update(body: body, masked_at: Time.zone.now)
  end

  def mask_pdf
    body = AlaveteliTextMasker.apply_masks(
      unmasked_body,
      content_type,
      masks
    )

    redaction_result = Thread.current[:pdf_redaction_result]
    Thread.current[:pdf_redaction_result] = nil

    if body.nil?
      Rails.logger.error(
        "PDF redaction failed for FoiAttachment##{id}"
      )
      store_redaction_metadata(redaction_result, success: false)
      return
    end

    update(body: body, masked_at: Time.zone.now)
    store_redaction_metadata(redaction_result, success: true)
  end

  def store_redaction_metadata(result, success:)
    return unless file_blob
    return unless result

    metadata = file_blob.metadata || {}
    metadata['redaction'] = {
      'strategy' => result.strategy.to_s,
      'matched_rules' => result.matched_rules,
      'unmatched_rules' => result.unmatched_rules,
      'warnings' => result.warnings,
      'success' => success,
      'redacted_at' => Time.zone.now.iso8601
    }
    file_blob.update(metadata: metadata)
  end

  def masks
    {
      censor_rules: info_request.applicable_censor_rules,
      masks: info_request.masks
    }
  end
end
