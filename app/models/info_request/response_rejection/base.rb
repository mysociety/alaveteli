class InfoRequest
  module ResponseRejection
    class Base
      attr_reader :info_request, :mail

      def initialize(info_request, mail)
        @info_request = info_request
        @mail = mail
      end

      def reject(_reason = nil)
        true
      end
    end
  end
end
