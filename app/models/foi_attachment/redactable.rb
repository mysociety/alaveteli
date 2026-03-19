module FoiAttachment::Redactable
  extend ActiveSupport::Concern

  def redacted?
    filename_redacted? || body_redacted?
  end

  private

  def filename_redacted?
    filename != redacted_filename
  end

  # This naive approach is likely to return true even if actual redactions are
  # not present. We do lots of transformations to the original body in one go,
  # so it would need a fair amount of work to tease these apart to check for
  # a diff that's explicitly down to one of the redaction mechanisms (text mask,
  # censor rule or replacement).
  def body_redacted?
    unmasked_body != body
  end
end
