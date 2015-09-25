# -*- encoding : utf-8 -*-
class InfoRequest
  module ResponseGatekeeper
    class AuthorityOnly < Base
      def allow?(email)
        @allow, @reason = calculate_allow_reason(info_request, email)
        allow
      end

      private

      def calculate_allow_reason(info_request, email)
        sender_email = MailHandler.get_from_address(email)
        if sender_email.nil?
          allow = false
          reason = _('Only the authority can reply to this request, but there is no "From" address to check against')
        else
          sender_domain = PublicBody.extract_domain_from_email(sender_email)
          reason = _("Only the authority can reply to this request, and I don't recognise the address this reply was sent from")
          allow = false
          # Allow any domain that has already sent reply
          info_request.who_can_followup_to.each do |_, email_address, _|
            request_domain = PublicBody.extract_domain_from_email(email_address)
            if request_domain == sender_domain
              allow = true
              reason = nil
            end
          end
        end

        [allow, reason]
      end
    end
  end
end
