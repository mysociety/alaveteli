# Extracts text from the masked body of an FoiAttachment for search indexing
class AttachmentToText
  def initialize(attachment)
    @attachment = attachment
  end

  def to_text
    text = MailHandler.get_attachment_text_one_file(
      attachment.content_type,
      attachment.default_body,
      attachment.charset
    )

    convert_string_to_utf8(text, 'UTF-8').string
  end

  protected

  attr_reader :attachment
end
