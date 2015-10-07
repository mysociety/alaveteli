# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseRejection
    class Bounce < Base
      def reject(reason = nil)
        if MailHandler.get_from_address(email).nil?
          # do nothing – can't bounce the mail as there's no address to send it
          # to
          true
        else
          if info_request.is_external?
            true
          else
            RequestMailer.
              stopped_responses(info_request, email).
                deliver
          end
        end
      end
    end
  end
end
