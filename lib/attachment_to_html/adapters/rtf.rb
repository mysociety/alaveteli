module AttachmentToHTML
    module Adapters
        # Convert application/rtf documents in to HTML
        class RTF

            attr_reader :attachment, :wrapper, :tmpdir

            # Public: Initialize a RTF converter
            #
            # attachment - the FoiAttachment to convert to HTML
            # opts       - a Hash of options (default: {}):
            #              :wrapper - String id of the div that wraps the
            #                         attachment body
            #              :tmpdir  - String name of directory to store the
            #                         converted document
            def initialize(attachment, opts = {})
                @attachment = attachment
                @wrapper = opts.fetch(:wrapper, 'wrapper')
                @tmpdir = opts.fetch(:tmpdir, ::Rails.root.join('tmp'))
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
                parsed_body
            end

            # Parse the output of the converted attachment so that we can pluck
            # the parts we need and insert in to our own sensible template
            #
            # Returns a Nokogiri::HTML::Document
            def parsed
                @parsed ||= Nokogiri::HTML.parse(convert)
            end

            def parsed_body
                parsed.css('body').inner_html
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

            def convert
                # Get the attachment body outside of the chdir call as getting
                # the body may require opening files too
                text = attachment_body

                @converted ||= Dir.chdir(tmpdir) do
                    tempfile = create_tempfile(text)

                    html = AlaveteliExternalCommand.run("unrtf", "--html",
                      tempfile.path, :timeout => 120
                    )

                    cleanup_tempfile(tempfile)

                    html
                end
            end

            def create_tempfile(text)
                tempfile = if RUBY_VERSION.to_f >= 1.9
                               Tempfile.new('foiextract', '.',
                                            :encoding => text.encoding)
                           else
                               Tempfile.new('foiextract', '.')
                           end
                tempfile.print(text)
                tempfile.flush
                tempfile
            end

            def cleanup_tempfile(tempfile)
                tempfile.close
                tempfile.delete
            end

            def attachment_body
                @attachment_body ||= attachment.body
            end

        end
    end
end
