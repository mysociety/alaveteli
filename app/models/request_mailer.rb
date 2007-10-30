# models/request_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.5 2007-10-30 14:23:21 francis Exp $

class RequestMailer < ActionMailer::Base

    def initial_request(info_request, outgoing_message)
        @from = info_request.incoming_email
        if MySociety::Config.getbool("STAGING_SITE", 1)
            @recipients = @from
        else
            @recipients = info_request.public_body.request_email
        end
        @subject    = 'Freedom of Information Request - ' + info_request.title
        @body       = {:info_request => info_request, :outgoing_message => outgoing_message}
    end

    # Copy of function from action_mailer/base.rb, which passes the
    # raw_email to the member function, as we want to record it.
    # script/mailin calls this function.
    def self.receive(raw_email)
        logger.info "Received mail:\n #{raw_email}" unless logger.nil?
        mail = TMail::Mail.parse(raw_email)
        mail.base64_decode
        new.receive(mail, raw_email)
    end


    def receive(email, raw_email)
        # Find which info requests the email is for
        info_requests = []
        for address in (email.to || []) + (email.cc || [])
            info_request = InfoRequest.find_by_incoming_email(address)
            info_requests.push(info_request) if info_request
        end

        # Send the message to each request
        for info_request in info_requests
            info_request.receive(email, raw_email)
        end
    end

end
