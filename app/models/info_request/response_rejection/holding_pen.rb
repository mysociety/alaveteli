# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseRejection
    class HoldingPen < Base
      attr_reader :holding_pen

      def initialize(info_request, email)
        super
        @holding_pen = InfoRequest.holding_pen_request
      end

      def reject(reason = nil)
        if info_request == holding_pen
          false
        else
          # TODO: Remove the second parameter to receive in 0.24
          holding_pen.receive(email, nil, false, reason)
        end
      end
    end
  end
end
