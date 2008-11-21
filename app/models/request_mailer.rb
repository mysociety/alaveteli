# models/request_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.67 2008-11-21 01:50:06 francis Exp $

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
        @recipients = RequestMailer.name_and_email_for_followup(info_request, incoming_message_followup)
        @subject    = RequestMailer.subject_for_followup(info_request, outgoing_message)
        @body       = {:info_request => info_request, :outgoing_message => outgoing_message,
            :incoming_message_followup => incoming_message_followup,
            :contact_email => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost') }
    end

    # Separate function, so can be called from controller for logging
    # XXX the condition checking valid_to_reply_to? also appears in views/request/_followup.rhtml,
    # it shouldn't really, should call something here.
    # XXX also OutgoingMessage.get_salutation
    def RequestMailer.name_and_email_for_followup(info_request, incoming_message_followup)
        if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
            return info_request.recipient_name_and_email
        else
            return incoming_message_followup.mail.from_addrs[0].quoted_full
        end
    end
    # Used in the preview of followup
    def RequestMailer.name_for_followup(info_request, incoming_message_followup)
        if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
            return info_request.public_body.name
        else
            return incoming_message_followup.safe_mail_from || info_request.public_body.name
        end
    end
    # Used when making list of followup places to remove duplicates
    def RequestMailer.email_for_followup(info_request, incoming_message_followup)
        if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
            return info_request.recipient_email
        else
            return incoming_message_followup.mail.from_addrs[0].spec
        end
    end
    def RequestMailer.subject_for_followup(info_request, outgoing_message)
        if outgoing_message.what_doing == 'internal_review'
            return "Internal review of " + info_request.email_subject_request
        else
            return info_request.email_subject_followup 
        end
    end

    # Used when an FOI officer uploads a response from their web browser - this is
    # the "fake" email used to store in the same format in the database as if they
    # had emailed it.
    def fake_response(info_request, from_user, body, attachment_name, attachment_content)
        @from = from_user.name_and_email
        @recipients = info_request.incoming_name_and_email
        @body = {
            :body => body
        }
        if !attachment_name.nil? && !attachment_content.nil?
            IncomingMessage # load global filename_to_mimetype XXX should move filename_to_mimetype to proper namespace
            calc_mime = filename_to_mimetype(attachment_name)
            if calc_mime
                content_type = calc_mime
            else
                content_type = 'application/octet-stream'
            end

            attachment :content_type => content_type,
                :body => attachment_content,
                :filename => attachment_name
        end
    end

    # Incoming message arrived for a request, but new responses have been stopped.
    def stopped_responses(info_request, email)
        @from = contact_from_name_and_email
        @recipients = email.from_addrs[0].quoted_full
        @subject = "Your response to an FOI request was not delivered"
        attachment :content_type => 'message/rfc822', :body => email.body
        @body = { 
            :info_request => info_request,
            :contact_email => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')     
        }
    end

    # An FOI response is outside the scope of the system, and needs admin attention
    def requires_admin(info_request)
        @from = info_request.user.name_and_email
        @recipients = contact_from_name_and_email
        @subject = "Unusual FOI response - " + info_request.title
        url = main_url(request_url(info_request))
        admin_url = request_admin_url(info_request)
        @body = {:info_request => info_request, :url => url, :admin_url => admin_url }
    end

    # Tell the requester that a new response has arrived
    def new_response(info_request, incoming_message)
        # Don't use login link here, just send actual URL. This is
        # because people tend to forward these emails amongst themselves.
        url = main_url(incoming_message_url(incoming_message))

        @from = contact_from_name_and_email
        @recipients = info_request.user.name_and_email
        @subject = "New response to your FOI request - " + info_request.title
        @body = { :incoming_message => incoming_message, :info_request => info_request, :url => url }
    end

    # Tell the requester that the public body is late in replying
    def overdue_alert(info_request, user)
        respond_url = respond_to_last_url(info_request) + "#followup"

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
        # Make a link going to the form to describe state, and which logs the
        # user in.
        post_redirect = PostRedirect.new(
            :uri => main_url(request_url(info_request)) + "#describe_state_form_1",
            :user_id => info_request.user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        @from = contact_from_name_and_email
        @recipients = info_request.user.name_and_email
        @subject = "Was the response you got the other day any good?"
        @body = { :incoming_message => incoming_message, :info_request => info_request, :url => url }
    end

    # Tell the requester that they need to clarify their request
    def not_clarified_alert(info_request, incoming_message)
        respond_url = show_response_url(:id => info_request.id, :incoming_message_id => incoming_message.id)
        respond_url = respond_url + "#followup" 

        post_redirect = PostRedirect.new(
            :uri => respond_url,
            :user_id => info_request.user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        @from = contact_from_name_and_email
        @recipients = info_request.user.name_and_email
        @subject = "Clarify your FOI request - " + info_request.title
        @body = { :incoming_message => incoming_message, :info_request => info_request, :url => url }
    end

    # Tell the requester that they need to clarify their request
    def comment_on_alert(info_request, comment)
        @from = contact_from_name_and_email
        @recipients = info_request.user.name_and_email
        @subject = "Somebody added a note to your FOI request - " + info_request.title
        @body = { :comment => comment, :info_request => info_request, :url => main_url(comment_url(comment)) }
    end
    def comment_on_alert_plural(info_request, count, earliest_unalerted_comment)
        @from = contact_from_name_and_email
        @recipients = info_request.user.name_and_email
        @subject = "Some notes have been added to your FOI request - " + info_request.title
        @body = { :count => count, :info_request => info_request, :url => main_url(comment_url(earliest_unalerted_comment)) }
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

        # Nothing found, so save in holding pen
        if reply_info_requests.size == 0 
            InfoRequest.holding_pen_request.receive(email, raw_email)
            return
        end

        # Send the message to each request, to be archived with it
        for reply_info_request in reply_info_requests
            reply_info_request.receive(email, raw_email)
        end
    end

    # Send email alerts for overdue requests
    def self.alert_overdue_requests()
        #STDERR.puts "alert_overdue_requests"
        info_requests = InfoRequest.find(:all, :conditions => [ "described_state = 'waiting_response' and awaiting_description = ?", false ], :include => [ :user ] )
        for info_request in info_requests
            alert_event_id = info_request.last_event_forming_initial_request.id
            # Only overdue requests
            if info_request.calculate_status == 'waiting_response_overdue'
                # For now, just to the user who created the request
                sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = 'overdue_1' and user_id = ? and info_request_id = ? and info_request_event_id = ?", info_request.user_id, info_request.id, alert_event_id])
                if sent_already.nil?
                    # Alert not yet sent for this user
                    #STDERR.puts "sending overdue alert to info_request " + info_request.id.to_s + " user " + info_request.user_id.to_s + " event " + alert_event_id
                    store_sent = UserInfoRequestSentAlert.new
                    store_sent.info_request = info_request
                    store_sent.user = info_request.user
                    store_sent.alert_type = 'overdue_1'
                    store_sent.info_request_event_id = alert_event_id
                    RequestMailer.deliver_overdue_alert(info_request, info_request.user)
                    store_sent.save!
                    #STDERR.puts "sent " + info_request.user.email
                end
            end
        end
    end

    # Send email alerts for new responses which haven't been classified. Goes
    # out 3 days after last update of event, then after 7.
    def self.alert_new_response_reminders
        self.alert_new_response_reminders_internal(3, 'new_response_reminder_1')
        self.alert_new_response_reminders_internal(7, 'new_response_reminder_2')
    end
    def self.alert_new_response_reminders_internal(days_since, type_code)
        #STDERR.puts "alert_new_response_reminders_internal days:" + days_since.to_s + " type: " + type_code
        info_requests = InfoRequest.find(:all, :conditions => [ "awaiting_description = ? and info_requests.updated_at < ? and url_title != 'holding_pen'", true, Time.now() - days_since.days ], :include => [ :user ], :order => "info_requests.id" )
        for info_request in info_requests
            alert_event_id = info_request.get_last_response_event_id
            last_response_message = info_request.get_last_response
            if alert_event_id.nil?
                raise "internal error, no last response while making alert new response reminder, request id " + info_request.id.to_s
            end
            # To the user who created the request
            sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = ? and user_id = ? and info_request_id = ? and info_request_event_id = ?", type_code, info_request.user_id, info_request.id, alert_event_id])
            if sent_already.nil?
                # Alert not yet sent for this user
                #STDERR.puts "sending " + type_code + " alert to info_request " + info_request.url_title + " user " + info_request.user.url_name + " event " + alert_event_id.to_s
                store_sent = UserInfoRequestSentAlert.new
                store_sent.info_request = info_request
                store_sent.user = info_request.user
                store_sent.alert_type = type_code
                store_sent.info_request_event_id = alert_event_id
                # XXX uses same template for reminder 1 and reminder 2 right now. 
                RequestMailer.deliver_new_response_reminder_alert(info_request, last_response_message)
                store_sent.save!
                #STDERR.puts "sent " + info_request.user.email
            end
        end
    end

    # Send email alerts for requests which need clarification. Goes out 3 days
    # after last update of event.
    def self.alert_not_clarified_request()
        #STDERR.puts "alert_not_clarified_request"
        info_requests = InfoRequest.find(:all, :conditions => [ "awaiting_description = ? and described_state = 'waiting_clarification' and info_requests.updated_at < ?", false, Time.now() - 3.days ], :include => [ :user ], :order => "info_requests.id" )
        for info_request in info_requests
            alert_event_id = info_request.get_last_response_event_id
            last_response_message = info_request.get_last_response
            if alert_event_id.nil?
                raise "internal error, no last response while making alert not clarified reminder, request id " + info_request.id.to_s
            end
            # To the user who created the request
            sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = 'not_clarified_1' and user_id = ? and info_request_id = ? and info_request_event_id = ?", info_request.user_id, info_request.id, alert_event_id])
            if sent_already.nil?
                # Alert not yet sent for this user
                #STDERR.puts "sending clarification reminder alert to info_request " + info_request.id.to_s + " user " + info_request.user_id.to_s + " event " + alert_event_id.to_s
                store_sent = UserInfoRequestSentAlert.new
                store_sent.info_request = info_request
                store_sent.user = info_request.user
                store_sent.alert_type = 'not_clarified_1'
                store_sent.info_request_event_id = alert_event_id
                RequestMailer.deliver_not_clarified_alert(info_request, last_response_message)
                store_sent.save!
                #STDERR.puts "sent " + info_request.user.email
            end
        end
    end

    # Send email alert to request submitter for new comments on the request.
    def self.alert_comment_on_request()
        #STDERR.puts "alert_comment_on_request"
        
        # We only check comments made in the last month - this means if the
        # cron jobs broke for more than a month events would be lost, but no
        # matter. I suspect the performance gain will be needed (with an index on updated_at)
        
        # XXX the :order part info_request_events.created_at is a work around
        # for a very old Rails bug which means eager loading does not respect
        # association orders.
        #   http://dev.rubyonrails.org/ticket/3438
        #   http://lists.rubyonrails.org/pipermail/rails-core/2006-July/001798.html
        # That that patch has not been applied, despite bribes of beer, is
        # typical of the lack of quality of Rails.
        
        info_requests = InfoRequest.find(:all, :conditions => [ "(select count(*) from info_request_events where event_type = 'comment' and info_request_events.info_request_id = info_requests.id and created_at > ?) > 0", Time.now() - 1.month ], :include => [ { :info_request_events => :user_info_request_sent_alerts } ], :order => "info_requests.id, info_request_events.created_at" )
        for info_request in info_requests
            #STDERR.puts "considering request " + info_request.id.to_s

            # Find the last comment, which we use as id to mark alert done
            last_comment_event = info_request.get_last_comment_event
            raise "expected comment event but got none" if last_comment_event.nil?

            # Count number of new comments to alert on
            earliest_unalerted_comment_event = nil
            count = 0
            for e in info_request.info_request_events.reverse
                # STDERR.puts "event " + e.id.to_s + " type " + e.event_type
                if e.event_type == 'comment'
                    alerted_for = e.user_info_request_sent_alerts.find(:first, :conditions => [ "alert_type = 'comment_1' and user_id = ?", info_request.user_id])
                    # STDERR.puts "is comment, alerted_for " + alerted_for.to_s
                    if alerted_for.nil?
                        # STDERR.puts "nil!"
                        count = count + 1
                        earliest_unalerted_comment_event = e
                    else
                        break
                    end
                end
            end
            #STDERR.puts "earliest_unalerted_comment_event " + earliest_unalerted_comment_event.to_s

            # Alert needs sending if there are new comments
            if count > 0
                store_sent = UserInfoRequestSentAlert.new
                store_sent.info_request = info_request
                store_sent.user = info_request.user
                store_sent.alert_type = 'comment_1'
                store_sent.info_request_event_id = last_comment_event.id
                if count > 1
                    #STDERR.puts "sending multiple comment on request alert to info_request " + info_request.id.to_s + " user " + info_request.user_id.to_s + " count " + count.to_s + " earliest "  + earliest_unalerted_comment_event.id.to_s
                    RequestMailer.deliver_comment_on_alert_plural(info_request, count, earliest_unalerted_comment_event.comment)
                elsif count == 1
                    #STDERR.puts "sending comment on request alert to info_request " + info_request.id.to_s + " user " + info_request.user_id.to_s + " event " + last_comment_event.id.to_s
                    RequestMailer.deliver_comment_on_alert(info_request, last_comment_event.comment)
                else
                    raise "internal error"
                end
                store_sent.save!
                #STDERR.puts "sent " + info_request.user.email
            end
        end
    end


end


