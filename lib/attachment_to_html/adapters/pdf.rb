# -*- encoding : utf-8 -*-
module AttachmentToHTML
  module Adapters
    # Convert application/pdf documents in to HTML
    class PDF < Adapter
      TOO_MANY_IMAGES = 51

      attr_reader :tmpdir

      # Public: Initialize a PDF converter
      #
      # attachment - the FoiAttachment to convert to HTML
      # opts       - a Hash of options (default: {}):
      #              :tmpdir  - String name of directory to store the
      #                         converted document
      def initialize(attachment, opts = {})
        super
        @tmpdir = opts.fetch(:tmpdir, ::Rails.root.join('tmp'))
      end

      # Public: Was the document conversion successful?
      #
      # Returns a Boolean
      def success?
        return false if contains_too_many_images?
        has_content? || contains_images?
      end

      private

      def parse_body
        conversion = convert
        match = conversion ? conversion.match(/<body[^>]*>(.*?)<\/body>/mi) : nil
        match ? match[1] : ''
      end

      # Works around https://bugs.freedesktop.org/show_bug.cgi?id=77932 in pdftohtml
      def contains_too_many_images?
        number_of_images_in_body >= TOO_MANY_IMAGES
      end

      def number_of_images_in_body
        body.scan(/<img[^>]*>/i).size
      end

      def convert
        # Get the attachment body outside of the chdir call as getting
        # the body may require opening files too
        text = attachment_body

        @converted ||= Dir.chdir(tmpdir) do
          tempfile = create_tempfile(text)
          html = AlaveteliExternalCommand.run("pdftohtml",
                                              "-nodrm",
                                              "-zoom", "1.0",
                                              "-stdout",
                                              "-enc", "UTF-8",
                                              "-noframes",
                                              "./#{File.basename(tempfile.path)}",
                                              :timeout => 30,
                                              :binary_output => false)

          cleanup_tempfile(tempfile)
          html
        end
      end
    end
  end
end
