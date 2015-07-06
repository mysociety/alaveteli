# -*- encoding : utf-8 -*-
module AttachmentToHTML
    module Adapters
        # Convert text/plain documents in to HTML
        class Text < Adapter
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
         end
    end
end
