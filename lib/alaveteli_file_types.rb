require "marcel"

class AlaveteliFileTypes
  # To add an image, create a file with appropriate name corresponding to the
  # mime type in app/assets/images/content_type/ e.g. icon_image_tiff_large.png
  FileExtensionToMimeType = {
    'csv' => 'text/csv',
    "txt" => 'text/plain',
    "pdf" => 'application/pdf',
    "rtf" => 'application/rtf',
    "doc" => 'application/vnd.ms-word',
    "docx" => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    "xls" => 'application/vnd.ms-excel',
    "xlsx" => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    "ppt" => 'application/vnd.ms-powerpoint',
    "pptx" => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    "eml" => 'message/rfc822',
    "oft" => 'application/vnd.ms-outlook',
    "msg" => 'application/vnd.ms-outlook',
    "tnef" => 'application/ms-tnef',
    "tif" => 'image/tiff',
    "gif" => 'image/gif',
    "jpeg" => 'image/jpeg',
    "jpg" => 'image/jpeg',
    "png" => 'image/png',
    "bmp" => 'image/bmp',
    "htm" => 'text/html',
    "html" => 'text/html',
    "vcf" => 'text/x-vcard',
    "zip" => 'application/zip',
    "delivery-status" => 'message/delivery-status'
  }
  # Duplicate MIME types (e.g. image/jpeg) map to the last extension listed
  # above, so preferred extensions (jpg, html) should come after aliases.
  FileExtensionToMimeTypeRev = FileExtensionToMimeType.invert

  class << self
    def all_extensions
      FileExtensionToMimeType.keys
    end

    # Given file name and its content, return most likely type
    def filename_and_content_to_mimetype(filename, content)
      filename_to_mimetype(filename) || content_to_mimetype(content)
    end

    def content_to_mimetype(content)
      mime_type = Marcel::MimeType.for(StringIO.new(content))
      return mime_type unless mime_type == 'application/octet-stream'

      # Marcel cannot detect plain text from content alone (unlike
      # libmagic/Mahoro). Check if content is valid text as a fallback.
      text_content?(content) ? 'text/plain' : mime_type
    end

    def filename_to_mimetype(filename)
      return nil unless filename

      if filename.match(/\.([^.]+)$/i)
        lext = $1.downcase
        if FileExtensionToMimeType.include?(lext)
          return FileExtensionToMimeType[lext]
        end
      end
      nil
    end

    def text_content?(content)
      return false if content.nil? || content.empty?

      content.force_encoding('UTF-8').valid_encoding? &&
        !content.match?(/[\x00-\x08\x0E-\x1F]/)
    end

    def mimetype_to_extension(mimetype)
      if FileExtensionToMimeTypeRev.include?(mimetype)
        return FileExtensionToMimeTypeRev[mimetype]
      end

      nil
    end
  end
end
