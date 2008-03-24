# models/request_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.28 2008-03-24 09:35:23 francis Exp $

class RequestMailer < ApplicationMailer
    
    # Email to public body requesting info
    def initial_request(info_request, outgoing_message)
        @from = info_request.incoming_name_and_email
        @recipients = info_request.recipient_name_and_email
        @subject    = info_request.email_subject_request
        @body       = {:info_request => info_request, :outgoing_message => outgoing_message,
            :contact_email => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost') }
    end

    # Later message to public body regarding existing request
    def followup(info_request, outgoing_message, incoming_message_followup)
        @from = info_request.incoming_name_and_email
        if incoming_message_followup.nil?
            @recipients = info_request.recipient_name_and_email
        else
            @recipients = incoming_message_followup.mail.from_addrs.to_s
        end
        @subject    = 'Re: Freedom of Information Request - ' + info_request.title
        @subject    = info_request.email_subject_followup
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
        url =  show_request_url(:url_title => info_request.url_title)
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

    # Tell the requester that the public body is late in replying
    def overdue_alert(info_request, user)
        last_response = info_request.get_last_response
        if last_response.nil?
            respond_url = show_response_no_followup_url(:id => info_request.id)
        else
            respond_url = show_response_url(:id => info_request.id, :incoming_message_id => last_response.id)
        end
        respond_url = respond_url + "#show_response_followup" 

        post_redirect = PostRedirect.new(
            :uri => respond_url,
            :user_id => user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        @from = contact_from_name_and_email
        @recipients = user.name_and_email
        @subject = "You're overdue a response to your FOI request - " + info_request.title
        @body = { :info_request => info_request, :url => url }
    end

    # Tell the requester that they need to say if the new response
    # contains info or not
    def new_response_reminder_alert(info_request, incoming_message)
        post_redirect = PostRedirect.new(
            :uri => describe_state_url(:id => info_request.id),
            :user_id => info_request.user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        @from = contact_from_name_and_email
        @recipients = info_request.user.name_and_email
        @subject = "Did your recent FOI response contain information? - " + info_request.title
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
        for address in (email.to || []) + (email.cc || [])
            reply_info_request = InfoRequest.find_by_incoming_email(address)
            reply_info_requests.push(reply_info_request) if reply_info_request
        end

        # Nothing found
        if reply_info_requests.size == 0 
            RequestMailer.deliver_bounced_message(email)
        end

        # Send the message to each request, to be archived with it
        for reply_info_request in reply_info_requests
            reply_info_request.receive(email, raw_email)
        end
    end

    # Send email alerts for overdue requests
    def self.alert_overdue_requests()
        #STDERR.puts "alert_overdue_requests"
        info_requests = InfoRequest.find(:all, :conditions => [ "described_state = 'waiting_response' and not awaiting_description" ], :include => [ :user ] )
        for info_request in info_requests
            # Only overdue requests
            if info_request.calculate_status == 'waiting_response_overdue'
                # For now, just to the user who created the request
                sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = 'overdue_1' and user_id = ? and info_request_id = ?", info_request.user_id, info_request.id])
                if sent_already.nil?
                    # Alert not yet sent for this user
                    STDERR.puts "sending overdue alert to info_request " + info_request.id.to_s + " user " + info_request.user_id.to_s
                    store_sent = UserInfoRequestSentAlert.new
                    store_sent.info_request = info_request
                    store_sent.user = info_request.user
                    store_sent.alert_type = 'overdue_1'
                    RequestMailer.deliver_overdue_alert(info_request, info_request.user)
                    store_sent.save!
                    #STDERR.puts "sent " + info_request.user.email
                end
            end
        end
    end

    # Send email alerts for new responses which haven't been
    # classified. Goes out 3 days after last update of event.
    def self.alert_new_response_reminders()
        #STDERR.puts "alert_new_response_reminders"
        info_requests = InfoRequest.find(:all, :conditions => [ "awaiting_description and info_requests.updated_at < ?", Time.now() - 3.days ], :include => [ :user ], :order => "info_requests.id" )
        for info_request in info_requests
            alert_event_id = info_request.get_last_response_event_id
            last_response_message = info_request.get_last_response
            if alert_event_id.nil?
                raise "internal error, no last response while making alert new response reminder, request id " + info_request.id.to_s
            end
            # To the user who created the request
            sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = 'new_response_reminder_1' and user_id = ? and info_request_id = ? and info_request_event_id = ?", info_request.user_id, info_request.id, alert_event_id])
            if sent_already.nil?
                # Alert not yet sent for this user
                STDERR.puts "sending new response reminder alert to info_request " + info_request.id.to_s + " user " + info_request.user_id.to_s + " event " + alert_event_id.to_s
                store_sent = UserInfoRequestSentAlert.new
                store_sent.info_request = info_request
                store_sent.user = info_request.user
                store_sent.alert_type = 'new_response_reminder_1'
                store_sent.info_request_event_id = alert_event_id
                RequestMailer.deliver_new_response_reminder_alert(info_request, last_response_message)
                store_sent.save!
                #STDERR.puts "sent " + info_request.user.email
            end
        end
    end

end


