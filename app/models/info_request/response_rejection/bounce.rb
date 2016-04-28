# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseRejection
    class Bounce < Base
      def reject(reason = nil)
        from_address = MailHandler.get_from_address(email)
        if from_address.nil? || from_address.downcase == info_request.incoming_email.downcase
          # do nothing – can't bounce the mail as there's no address to send it
          # to, or the mail is spoofing the request address, and we'll end up
          # in a loop if we bounce it.
          true
        else
          if info_request.is_external?
            true
          else
            RequestMailer.
              stopped_responses(info_request, email, raw_email_data).
                deliver
          end
        end
      end
    end
  end
end
