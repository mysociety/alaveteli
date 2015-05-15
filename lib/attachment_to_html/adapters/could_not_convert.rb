# -*- encoding : utf-8 -*-
module AttachmentToHTML
    module Adapters
        class CouldNotConvert

            attr_reader :attachment

            # Public: Initialize a PDF converter
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


            # Public: Was the document conversion successful?
            # As this is a fallback option and not doing anything dynamic
            # we're assuming this is successful whatever the case
            #
            # Returns true
            def success?
                true
            end

            private

            def parse_body
                "<p>Sorry, we were unable to convert this file to HTML. " \
                "Please use the download link at the top right.</p>"
            end

        end
    end
end
