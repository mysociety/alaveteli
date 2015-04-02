module AttachmentToHTML
    module Adapters
        # Convert application/pdf documents in to HTML
        class PDF
            TOO_MANY_IMAGES = 51

            attr_reader :attachment, :tmpdir

            # Public: Initialize a PDF converter
            #
            # attachment - the FoiAttachment to convert to HTML
            # opts       - a Hash of options (default: {}):
            #              :tmpdir  - String name of directory to store the
            #                         converted document
            def initialize(attachment, opts = {})
                @attachment = attachment
                @tmpdir = opts.fetch(:tmpdir, ::Rails.root.join('tmp'))
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
                return false if contains_too_many_images?
                has_content? || contains_images?
            end

            private

            def parse_body
                conversion = convert
                match = conversion ? conversion.match(/<body[^>]*>(.*?)<\/body>/mi) : nil
                match ? match[1] : ''
            end

            def has_content?
                !body.gsub(/\s+/,"").gsub(/\<[^\>]*\>/, "").empty?
            end

            def contains_images?
                body.match(/<img[^>]*>/mi) ? true : false
            end

            # Works around https://bugs.freedesktop.org/show_bug.cgi?id=77932 in pdftohtml
            def contains_too_many_images?
                number_of_images_in_body >= TOO_MANY_IMAGES
            end

            def number_of_images_in_body
                body.scan(/<img[^>]*>/i).size
            end

            def convert
                # Get the attachment body outside of the chdir call as getting
                # the body may require opening files too
                text = attachment_body

                @converted ||= Dir.chdir(tmpdir) do
                    tempfile = create_tempfile(text)

                    html = AlaveteliExternalCommand.run("pdftohtml",
                      "-nodrm", "-zoom", "1.0", "-stdout", "-enc", "UTF-8",
                      "-noframes", tempfile.path, :timeout => 30, :binary_output => false
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
