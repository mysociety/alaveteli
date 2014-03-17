module AttachmentToHTML
    module Adapters
        class CouldNotConvert

            attr_reader :attachment, :wrapper

            # Public: Initialize a Text converter
            #
            # attachment - the FoiAttachment to convert to HTML
            # opts       - a Hash of options (default: {}):
            #              :wrapper - String id of the div that wraps the
            #                         attachment body
            def initialize(attachment, opts = {})
                @attachment = attachment
                @wrapper = opts.fetch(:wrapper, 'wrapper')
            end

            # Public: Convert the attachment to HTML
            #
            # Returns a String
            def to_html
                @html ||= generate_html
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

            def generate_html
                html =  "<!DOCTYPE html>"
                html += "<html>"
                html += "<head>"
                html += "<title>#{ title }</title>"
                html += "</head>"
                html += "<body>"
                html += "<div id=\"#{ wrapper }\">"
                html += "<div id=\"view-html-content\">"
                html += body
                html += "</div>"
                html += "</div>"
                html += "</body>"
                html += "</html>"
            end

            def title
                @title ||= attachment.display_filename
            end

            def body
                "<p>Sorry, we were unable to convert this file to HTML. " \
                "Please use the download link at the top right.</p>"
            end

        end
    end
end