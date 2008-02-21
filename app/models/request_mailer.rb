# models/request_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.22 2008-02-21 20:10:21 francis Exp $

class RequestMailer < ApplicationMailer
    
    # We always set Reply-To when we set Sender to be different from From,
    # since some email clients seem to erroneously use the envelope from when
    # they shouldn't, and this might help. (Have had mysterious cases of a
    # reply coming in duplicate from a public body to both From and envelope
    # from)
    
    # Email to public body requesting info
    def initial_request(info_request, outgoing_message)
        @from = info_request.incoming_name_and_email
        headers 'Sender' => info_request.envelope_name_and_email, 
                'Reply-To' => @from
        @recipients = info_request.recipient_name_and_email
        @subject    = 'Freedom of Information Request - ' + info_request.title
        @body       = {:info_request => info_request, :outgoing_message => outgoing_message,
            :contact_email => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost') }
    end

    # Later message to public body regarding existing request
    def followup(info_request, outgoing_message, incoming_message_followup)
        @from = info_request.incoming_name_and_email
        headers 'Sender' => info_request.envelope_name_and_email,
                'Reply-To' => @from
        @recipients = incoming_message_followup.mail.from_addrs.to_s
        @subject    = 'Re: Freedom of Information Request - ' + info_request.title
        @body       = {:info_request => info_request, :outgoing_message => outgoing_message,
            :incoming_message_followup => incoming_message_followup,
            :contact_email => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost') }
    end

    # Incoming message arrived at FOI address, but hasn't got To:/CC: of valid request
    def bounced_message(email)
        @from = contact_from_name_and_email
        @recipients = @from
        @subject = "Incoming email to unknown FOI request"
        email.setup_forward(self)
    end

    # An FOI response is outside the scope of the system, and needs admin attention
    def requires_admin(info_request)
        @from = contact_from_name_and_email
        @recipients = @from
        @subject = "Unusual FOI response, requires admin attention"
        # XXX these are repeats of things in helpers/link_to_helper.rb, and shouldn't be
        url =  show_request_url(:id => info_request)
        admin_url =  MySociety::Config.get("ADMIN_BASE_URL", "/admin/") + 'request/show/' + info_request.id.to_s
        @body       = {:info_request => info_request, :url => url, :admin_url => admin_url }
    end

    # Tell the requester that a new response has arrived
    def new_response(info_request, incoming_message)
        post_redirect = PostRedirect.new(
            :uri => describe_state_url(:id => info_request.id),
            :user_id => info_request.user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        @from = contact_from_name_and_email
        @recipients = info_request.user.name_and_email
        @subject = "New response to your FOI request - " + info_request.title
        @body = { :incoming_message => incoming_message, :info_request => info_request, :url => url }
    end

    # Class function, called by script/mailin with all incoming responses.
    # [ This is a copy (Monkeypatch!) of function from action_mailer/base.rb,
    # but which additionally passes the raw_email to the member function, as we
    # want to record it. ]
    def self.receive(raw_email)
        logger.info "Received mail:\n #{raw_email}" unless logger.nil?
        mail = TMail::Mail.parse(raw_email)
        mail.base64_decode
        new.receive(mail, raw_email)
    end

    # Member function, called on the new class made in self.receive above
    def receive(email, raw_email)
        # Find which info requests the email is for
        reply_info_requests = []
        bounce_info_requests = []
        for address in (email.to || []) + (email.cc || [])
            reply_info_request = InfoRequest.find_by_incoming_email(address)
            reply_info_requests.push(reply_info_request) if reply_info_request
            bounce_info_request = InfoRequest.find_by_envelope_email(address)
            bounce_info_requests.push(bounce_info_request) if bounce_info_request
        end

        # Nothing found
        if reply_info_requests.size == 0 && bounce_info_requests.size == 0
            RequestMailer.deliver_bounced_message(email)
        end

        # Send the message to each request, to be archived with it
        for reply_info_request in reply_info_requests
            reply_info_request.receive(email, raw_email, false)
        end
        for bounce_info_request in bounce_info_requests
            bounce_info_request.receive(email, raw_email, true)
        end
    end

end
