# -*- encoding : utf-8 -*-
module AttachmentToHTML
    module Adapters
        # Renders the attachment in a Google Docs Viewer
        class GoogleDocsViewer

            attr_reader :attachment, :attachment_url

            # Public: Initialize a GoogleDocsViewer converter
            #
            # attachment - the FoiAttachment to convert to HTML
            # opts       - a Hash of options (default: {}):
            #              :attachment_url - a String url to the attachment for
            #                                Google to render (default: nil)
            def initialize(attachment, opts = {})
                @attachment = attachment
                @attachment_url = opts.fetch(:attachment_url, nil)
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

            # Public: Was the document conversion successful?
            # We can't really tell whether the document conversion has been
            # successful as such; We're assuming that given a correctly
            # constructed iframe (which is tested) that Google will make this
            # Just Work.
            #
            # Returns true
            def success?
                true
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
