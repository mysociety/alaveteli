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
                html = Nokogiri::HTML.parse(convert)
                inject_title(html)
                inject_wrapper(html)
                html.to_html
            end

            def title
                attachment.display_filename
            end

            def body
                attachment.body
            end

            def convert
                Dir.chdir(tmpdir) do
                    tempfile = create_tempfile
                    write_body_to_tempfile(tempfile)

                    html = AlaveteliExternalCommand.run("unrtf", "--html",
                      tempfile.path, :timeout => 120
                    )

                    cleanup_tempfile(tempfile)

                    html
                end
            end

            def create_tempfile
                if RUBY_VERSION.to_f >= 1.9
                    Tempfile.new('foiextract', '.', :encoding => text.encoding)
                else
                    Tempfile.new('foiextract', '.')
                end
            end

            def write_body_to_tempfile(tempfile)
                tempfile.print(body)
                tempfile.flush
            end

            def cleanup_tempfile(tempfile)
                tempfile.close
                tempfile.delete
            end

            def inject_title(html)
                html.title = title
            end

            def inject_wrapper(html)
                html.css('body').wrap(wrapper_div)
            end

            def wrapper_div
                %Q(<div id="#{ wrapper }"></div>)
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
