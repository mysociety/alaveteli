require 'nokogiri'

module AttachmentToHTML
    module Adapters
        # Convert text/plain documents in to HTML
        class Text

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
            #
            # Returns a Boolean
            def success?
                has_content? || contains_images?
            end

            private

            def generate_html
                html =  "<!DOCTYPE html>"
                html += "<html>"
                html += "<head>"
                html += "<title>#{ title }</title>"
                html += "</head>"
                html += "<body>"
                html += "<div id=\"#{ wrapper }\">#{ body }</div>"
                html += "</body>"
                html += "</html>"
            end

            def title
                attachment.display_filename
            end

            def body
                text = attachment.body.strip
                text = CGI.escapeHTML(text)
                text = MySociety::Format.make_clickable(text)
                text = text.gsub(/\n/, '<br>')
            end

            # Does the body element have any content, excluding HTML tags?
            #
            # Returns a Boolean
            def has_content?
                !parsed.css('body').inner_text.empty?
            end

            def contains_images?
                parsed.css('body img').any?
            end

            # Parse the output of to_html to check for success
            #
            # Returns a Nokogiri::HTML::Document
            def parsed
                @parsed ||= Nokogiri::HTML.parse(to_html)
            end

        end
    end
end
