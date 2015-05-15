# -*- encoding : utf-8 -*-
module AttachmentToHTML
    module Adapters
        # Convert application/rtf documents in to HTML
        class RTF

            attr_reader :attachment, :tmpdir

            # Public: Initialize a RTF converter
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
                has_content? || contains_images?
            end

            private

            def parse_body
                match = convert.match(/<body[^>]*>(.*?)<\/body>/mi)
                match ? match[1] : ''
            end

            def has_content?
                !body.gsub(/\s+/,"").gsub(/\<[^\>]*\>/, "").empty?
            end

            def contains_images?
                body.match(/<img[^>]*>/mi) ? true : false
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

                    sanitize_converted(html)
                end

            end

            # Works around http://savannah.gnu.org/bugs/?42015 in unrtf ~> 0.21
            def sanitize_converted(html)
                html.nil? ? html = '' : html

                invalid = %Q(<!DOCTYPE html PUBLIC -//W3C//DTD HTML 4.01 Transitional//EN>)
                valid   = %Q(<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN>")
                if html.include?(invalid)
                   html.sub!(invalid, valid)
                end
                html
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
