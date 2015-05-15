# -*- encoding : utf-8 -*-
module AttachmentToHTML
    module Adapters
        # Convert text/plain documents in to HTML
        class Text

            attr_reader :attachment

            # Public: Initialize a Text converter
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
            #
            # Returns a Boolean
            def success?
                has_content? || contains_images?
            end

            private

            def convert
                text = attachment.body.strip
                text = CGI.escapeHTML(text)
                text = MySociety::Format.make_clickable(text)
                text = text.gsub(/\n/, '<br>')
            end

            def parse_body
                convert
            end

            def has_content?
                !body.gsub(/\s+/,"").gsub(/\<[^\>]*\>/, "").empty?
            end

            def contains_images?
                body.match(/<img[^>]*>/mi) ? true : false
            end

         end
    end
end
