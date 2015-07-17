module AttachmentToHTML
  class Adapter
    attr_reader :attachment

    # Public: Initialize a converter
    #
    # attachment - the FoiAttachment to convert to HTML
    # opts       - a Hash of options (default: {}):
    #              No options currently accepted
    def initialize(attachment, opts = {})
      @attachment = attachment
    end

    # Public: The title to use in the <title> tag
    #
    # Returns a String
    def title
      @title ||= attachment.display_filename
    end

    # Public: The contents of the extracted html <body> tag
    #
    # Returns a String
    def body
      @body ||= parse_body
    end

    def parse_body
      convert
    end

    # Public: Was the document conversion successful?
    #
    # Returns true
    def success?
      true
    end

    def has_content?
      !body.gsub(/\s+/,"").gsub(/\<[^\>]*\>/, "").empty?
    end

    def contains_images?
      body.match(/<img[^>]*>/mi)
    end

    def create_tempfile(text)
      tempfile = if RUBY_VERSION.to_f >= 1.9
        Tempfile.new('foiextract', '.', :encoding => text.encoding)
      else
        Tempfile.new('foiextract', '.')
      end
      tempfile.print(text)
      tempfile.flush
      tempfile
    end

    def cleanup_tempfile(tempfile)
      tempfile.close
      tempfile.delete
    end

    def attachment_body
      @attachment_body ||= attachment.default_body
    end
  end
end
