class InfoRequest
  module ResponseRejection
    class Base
      attr_reader :info_request, :mail, :inbound_email

      def initialize(info_request, mail, inbound_email)
        @info_request = info_request
        @mail = mail
        @inbound_email = inbound_email
      end

      def reject(_reason = nil)
        true
      end
    end
  end
end
