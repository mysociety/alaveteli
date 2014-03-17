module AttachmentToHTML
    module Adapters
        # Renders the attachment in a Google Docs Viewer
        class GoogleDocsViewer

            attr_reader :attachment, :wrapper, :attachment_url

            # Public: Initialize a PDF converter
            #
            # attachment - the FoiAttachment to convert to HTML
            # opts       - a Hash of options (default: {}):
            #              :wrapper - String id of the div that wraps the
            #                         attachment body
            #                         (default: 'wrapper_google_embed')
            #              :attachment_url - a String url to the attachment for
            #                                Google to render (default: nil)
            def initialize(attachment, opts = {})
                @attachment = attachment
                @wrapper = opts.fetch(:wrapper, 'wrapper_google_embed')
                @attachment_url = opts.fetch(:attachment_url, nil)
            end

            # Public: Convert the attachment to HTML
            #
            # Returns a String
            def to_html
                @html ||= generate_html
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
                %Q(<iframe src="#{ protocol }://docs.google.com/viewer?url=#{ attachment_url }&amp;embedded=true" width="100%" height="100%" style="border: none;"></iframe>)
            end

            def protocol
                AlaveteliConfiguration.force_ssl ? 'https' : 'http'
            end

        end
    end
end
