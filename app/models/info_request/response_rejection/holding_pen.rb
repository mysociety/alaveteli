class InfoRequest
  module ResponseRejection
    class HoldingPen < Base
      attr_reader :holding_pen

      def initialize(info_request, mail)
        super
        @holding_pen = InfoRequest.holding_pen_request
      end

      def reject(reason = nil)
        if info_request == holding_pen
          false
        else
          holding_pen.receive(mail, { rejected_reason: reason })
        end
      end
    end
  end
end
