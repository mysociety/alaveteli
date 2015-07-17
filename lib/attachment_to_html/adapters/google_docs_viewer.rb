# -*- encoding : utf-8 -*-
module AttachmentToHTML
  module Adapters
    # Renders the attachment in a Google Docs Viewer
    #
    # We can't really tell whether the document conversion has been
    # successful as such; We're assuming that given a correctly
    # constructed iframe (which is tested) that Google will make this
    # Just Work.
    class GoogleDocsViewer < Adapter
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

      private

      def parse_body
        %Q(<iframe src="#{ protocol }://docs.google.com/viewer?url=#{ attachment_url }&amp;embedded=true" width="100%" height="100%" style="border: none;"></iframe>)
      end

      def protocol
        AlaveteliConfiguration.force_ssl ? 'https' : 'http'
      end
    end
  end
end
