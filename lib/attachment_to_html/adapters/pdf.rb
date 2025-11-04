module AttachmentToHTML
  module Adapters
    # Inline application/pdf documents in an iframe
    class PDF < Adapter
      attr_reader :attachment_url

      def initialize(attachment, opts = {})
        super
        @attachment_url = opts.fetch(:attachment_url, nil)
      end

      def embed?
        true
      end

      private

      def parse_body
        %Q(<iframe src="#{attachment_url}" width="100%" height="100%" style="border: none;"></iframe>)
      end
    end
  end
end
