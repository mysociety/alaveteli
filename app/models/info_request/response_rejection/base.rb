# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseRejection
    class Base
      attr_reader :info_request, :email

      def initialize(info_request, email)
        @info_request = info_request
        @email = email
      end

      def reject(reason = nil)
        true
      end
    end
  end
end
