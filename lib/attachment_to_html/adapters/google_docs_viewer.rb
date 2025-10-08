module AttachmentToHTML
  module Adapters
    # Renders the attachment in a Google Docs Viewer
    #
    # We can't really tell whether the document conversion has been
    # successful as such; We're assuming that given a correctly
    # constructed iframe (which is tested) that Google will make this
    # Just Work.
    class GoogleDocsViewer < Adapter
      # rubocop:disable Layout/LineLength
      VIEWABLE_CONTENT_TYPES = [
        'application/pdf', # .pdf
        'image/tiff', # .tiff
        'application/vnd.ms-word', # .doc
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document', # .docx
        'application/vnd.ms-powerpoint', # .ppt
        'application/vnd.openxmlformats-officedocument.presentationml.presentation', # .pptx
        'application/vnd.ms-excel', # .xls
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', # .xlsx
        'text/csv' # csv
      ].freeze
      # rubocop:enable Layout/LineLength

      # Whether this type can be shown in the Google Docs Viewer.
      # The full list of supported types can be found at
      #   https://docs.google.com/support/bin/answer.py?hl=en&answer=1189935
      def self.viewable?(content_type)
        VIEWABLE_CONTENT_TYPES.include?(content_type)
      end

      attr_reader :attachment_url

      # Public: Initialize a GoogleDocsViewer converter
      #
      # attachment - the FoiAttachment to convert to HTML
      # opts       - a Hash of options (default: {}):
      #              :attachment_url - a String url to the attachment for
      #                                Google to render (default: nil)
      def initialize(attachment, opts = {})
        super
        @attachment_url = opts.fetch(:attachment_url, nil)
      end

      def embed?
        true
      end

      private

      def parse_body
        %Q(<iframe src="https://docs.google.com/viewer?url=#{Rack::Utils.escape(attachment_url)}&amp;embedded=true" width="100%" height="100%" style="border: none;"></iframe>)
      end
    end
  end
end
