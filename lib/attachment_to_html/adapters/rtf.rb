module AttachmentToHTML
  module Adapters
    # Convert application/rtf documents in to HTML
    class RTF < Adapter
      class Scrubber < Rails::HTML::PermitScrubber
        # Basic elements and attributes UnRTF generates (see its html.conf).
        # Its font and style formatting is dropped so it doesn't clash with the
        # page. Anything else is unwrapped, keeping its content as inert text.
        ALLOWED_TAGS = %w(
          body a b big br center div hr i img li ol p s small span sub sup
          table td tr u ul
        ).freeze

        ALLOWED_ATTRIBUTES = %w(align border href src).freeze

        # Tags to completely remove, along with the inner content.
        PRUNED_TAGS = %w(
          head iframe math noembed noframes noscript script style svg template
          title xmp
        ).freeze

        def initialize
          super
          self.tags = ALLOWED_TAGS
          self.attributes = ALLOWED_ATTRIBUTES
        end

        protected

        def scrub_node(node)
          if PRUNED_TAGS.include?(node.name)
            node.remove
          else
            super
          end
        end
      end

      attr_reader :tmpdir

      # Public: Initialize a RTF converter
      #
      # attachment - the FoiAttachment to convert to HTML
      # opts       - a Hash of options (default: {}):
      #              :tmpdir  - String name of directory to store the
      #                         converted document
      def initialize(attachment, opts = {})
        super
        @tmpdir = opts.fetch(:tmpdir, ::Rails.root.join('tmp'))
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

      def convert
        # Get the attachment body outside of the chdir call as getting
        # the body may require opening files too
        text = attachment_body

        @converted ||= Dir.chdir(tmpdir) do
          tempfile = create_tempfile(text)

          html = AlaveteliExternalCommand.run("unrtf", "--html",
                                              tempfile.path, timeout: 120
                                              )

          cleanup_tempfile(tempfile)

          sanitize_converted(html)
        end
      end

      # Works around http://savannah.gnu.org/bugs/?42015 in unrtf ~> 0.21
      def sanitize_converted(html)
        html.nil? ? html = '' : html
        html = Loofah.scrub_fragment(html, Scrubber.new).to_html

        invalid =
          %Q(<!DOCTYPE html PUBLIC -//W3C//DTD HTML 4.01 Transitional//EN>)
        valid =
          %Q(<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN>")

        html.sub!(invalid, valid) if html.include?(invalid)
        html
      end
    end
  end
end
