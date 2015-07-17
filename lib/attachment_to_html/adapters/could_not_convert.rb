# -*- encoding : utf-8 -*-
module AttachmentToHTML
  module Adapters
    # As this is a fallback option and not doing anything dynamic
    # we're assuming this is successful whatever the case
    class CouldNotConvert < Adapter
      private

      def parse_body
        "<p>Sorry, we were unable to convert this file to HTML. " \
          "Please use the download link at the top right.</p>"
      end
    end
  end
end
