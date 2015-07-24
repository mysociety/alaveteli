# -*- encoding : utf-8 -*-
class AlaveteliFileTypes
  # To add an image, create a file with appropriate name corresponding to the
  # mime type in public/images e.g. icon_image_tiff_large.png
  FileExtensionToMimeType = {
    "txt" => 'text/plain',
    "pdf" => 'application/pdf',
    "rtf" => 'application/rtf',
    "doc" => 'application/vnd.ms-word',
    "docx" => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    "xls" => 'application/vnd.ms-excel',
    "xlsx" => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    "ppt" => 'application/vnd.ms-powerpoint',
    "pptx" => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    "oft" => 'application/vnd.ms-outlook',
    "msg" => 'application/vnd.ms-outlook',
    "tnef" => 'application/ms-tnef',
    "tif" => 'image/tiff',
    "gif" => 'image/gif',
    "jpg" => 'image/jpeg', # TODO: add jpeg
    "png" => 'image/png',
    "bmp" => 'image/bmp',
    "html" => 'text/html', # TODO: add htm
    "vcf" => 'text/x-vcard',
    "zip" => 'application/zip',
    "delivery-status" => 'message/delivery-status'
  }
  # TODO: doesn't have way of choosing default for inverse map - might want to add
  # one when you need it
  FileExtensionToMimeTypeRev = FileExtensionToMimeType.invert

  class << self
    def all_extensions
      return FileExtensionToMimeType.keys
    end

    # Given file name and its content, return most likely type
    def filename_and_content_to_mimetype(filename, content)
      # Try filename
      ret = filename_to_mimetype(filename)
      if !ret.nil?
        return ret
      end

      # Otherwise look inside the file to work out the type.
      # Mahoro is a Ruby binding for libmagic.
      m = Mahoro.new(Mahoro::MIME)
      mahoro_type = m.buffer(content)
      mahoro_type.strip!
      # TODO: we shouldn't have to check empty? here, but Mahoro sometimes returns a blank line :(
      # e.g. for InfoRequestEvent 17930
      if mahoro_type.nil? || mahoro_type.empty?
        return nil
      end
      # text/plain types sometimes come with a charset
      mahoro_type.match(/^(.*);/)
      if $1
        mahoro_type = $1
      end
      # see if looks like a content type, or has something in it that does
      # and return that
      # mahoro returns junk "\012- application/msword" as mime type.
      mahoro_type.match(/([a-z0-9.-]+\/[a-z0-9.-]+)/)
      if $1
        return $1
      end
      # otherwise we got junk back from mahoro
      return nil
    end

    def filename_to_mimetype(filename)
      if !filename
        return nil
      end
      if filename.match(/\.([^.]+)$/i)
        lext = $1.downcase
        if FileExtensionToMimeType.include?(lext)
          return FileExtensionToMimeType[lext]
        end
      end
      return nil
    end

    def mimetype_to_extension(mimetype)
      if FileExtensionToMimeTypeRev.include?(mimetype)
        return FileExtensionToMimeTypeRev[mimetype]
      end
      return nil
    end
  end
end
