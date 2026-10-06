# Handles the masking of FoiAttachment records. Masking is the process of
# applying TextMask and CensorRule redactions.
module FoiAttachment::Maskable
  extend ActiveSupport::Concern

  included do
    scope :masked, -> { where.not(masked_at: nil) }
    scope :unmasked, -> { where(masked_at: nil) }
  end

  def masked?
    file.attached? && masked_at.present? && masked_at < Time.zone.now
  end

  def masking_failed?
    masking_failed_at.present?
  end

  def mask
    return if masking_failed?
    return if raw_email_erased? && masked?

    body = apply_masks(unmasked_body, content_type, redacted_attribute: :body)
    body = sanitise_html(body) if content_type == 'text/html'
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

  def apply_masks(text, content_type = 'text/plain', redacted_attribute:, redactable: self)
    info_request.apply_masks(
      text, content_type,
      redactable: redactable, redacted_attribute: redacted_attribute
    )
  end

  # The body as served in a request zip. Masked again because the rules can
  # match text that couldn't be reached in the stored body, so the redaction
  # is tracked against its own attribute.
  def masked_default_body
    apply_masks(default_body, content_type, redacted_attribute: :default_body)
  end

  # As above, for the "View as HTML" rendering. Takes the same options as
  # #body_to_html so callers can pass the attachment URL and surrounding
  # chrome.
  #
  # TODO: This forces binary masking by passing `nil` content_type to mirror
  # previous behaviour where masks were being applied at controller level. We
  # should be able to pass `text/html` instead.
  def masked_body_to_html(**kwargs)
    apply_masks(body_to_html(**kwargs), nil,
                redacted_attribute: :body_to_html)
  end

  private

  def sanitise_html(html)
    html = collapse_redundant_nesting(html)
    Loofah.html5_document(html) { |config| config[:max_tree_depth] = 800 }.
      scrub!(:prune).
      to_html(encoding: 'UTF-8')

  rescue ArgumentError
    sanitise_html_as_text(html)
  end

  def collapse_redundant_nesting(html)
    html.
      gsub(%r{(?:<div>\s*){30,}}i, '<div>').
      gsub(%r{(?:</div>\s*){30,}}i, '</div>')
  end

  def sanitise_html_as_text(html)
    CGI.escapeHTML(html.gsub(/<[^>]+>/, ' ').squeeze(' ').strip)
  end
end
