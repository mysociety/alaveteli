# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseRejection
    class Base
      attr_reader :info_request, :email, :raw_email_data

      def initialize(info_request, email, raw_email_data)
        @info_request = info_request
        @email = email
        @raw_email_data = raw_email_data
      end

      def reject(reason = nil)
        true
      end
    end
  end
end
