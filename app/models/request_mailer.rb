# models/request_mailer.rb:
# Alerts relating to requests.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_mailer.rb,v 1.89 2009-10-04 21:53:54 francis Exp $

require 'alaveteli_file_types'

class RequestMailer < ApplicationMailer
    

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
            content_type = AlaveteliFileTypes.filename_to_mimetype(attachment_name) || 'application/octet-stream'

            attachment :content_type => content_type,
                :body => attachment_content,
                :filename => attachment_name
        end
    end

    # Incoming message arrived for a request, but new responses have been stopped.
    def stopped_responses(info_request, email, raw_email_data)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # we don't care about bounces, likely from spammers
                'Auto-Submitted' => 'auto-replied' # http://tools.ietf.org/html/rfc3834
        @recipients = email.from_addrs[0].to_s
        @subject = "Your response to an FOI request was not delivered"
        attachment :content_type => 'message/rfc822', :body => raw_email_data,
            :filename => "original.eml", :transfer_encoding => '7bit', :content_disposition => 'inline'
        @body = { 
            :info_request => info_request,
            :contact_email => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')     
        }
    end

    # An FOI response is outside the scope of the system, and needs admin attention
    def requires_admin(info_request)
        @from = info_request.user.name_and_email
        @recipients = contact_from_name_and_email
        @subject = _("FOI response requires admin - ") + info_request.title
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
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = info_request.user.name_and_email
        @subject = _("New response to your FOI request - ") + info_request.title
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
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = user.name_and_email
        @subject = _("Delayed response to your FOI request - ") + info_request.title
        @body = { :info_request => info_request, :url => url }
    end

    # Tell the requester that the public body is very late in replying
    def very_overdue_alert(info_request, user)
        respond_url = respond_to_last_url(info_request) + "#followup"

        post_redirect = PostRedirect.new(
            :uri => respond_url,
            :user_id => user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = user.name_and_email
        @subject = _("You're long overdue a response to your FOI request - ") + info_request.title
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
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = info_request.user.name_and_email
        @subject = _("Was the response you got to your FOI request any good?")
        @body = { :incoming_message => incoming_message, :info_request => info_request, :url => url }
    end

    # Tell the requester that someone updated their old unclassified request
    def old_unclassified_updated(info_request)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = info_request.user.name_and_email
        @subject = "Someone has updated the status of your request"
        url = main_url(request_url(info_request))
        @body = {:info_request => info_request, :url => url}
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
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = info_request.user.name_and_email
        @subject = "Clarify your FOI request - " + info_request.title
        @body = { :incoming_message => incoming_message, :info_request => info_request, :url => url }
    end

    # Tell requester that somebody add an annotation to their request
    def comment_on_alert(info_request, comment)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = info_request.user.name_and_email
        @subject = _("Somebody added a note to your FOI request - ") + info_request.title
        @body = { :comment => comment, :info_request => info_request, :url => main_url(comment_url(comment)) }
    end
    def comment_on_alert_plural(info_request, count, earliest_unalerted_comment)
        @from = contact_from_name_and_email
        headers 'Return-Path' => blackhole_email, 'Reply-To' => @from, # not much we can do if the user's email is broken
                'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
                'X-Auto-Response-Suppress' => 'OOF'
        @recipients = info_request.user.name_and_email
        @subject = _("Some notes have been added to your FOI request - ") + info_request.title
        @body = { :count => count, :info_request => info_request, :url => main_url(comment_url(earliest_unalerted_comment)) }
    end

    # Class function, called by script/mailin with all incoming responses.
    # [ This is a copy (Monkeypatch!) of function from action_mailer/base.rb,
    # but which additionally passes the raw_email to the member function, as we
    # want to record it. 
    #
    # That is because we want to be sure we properly record the actual message
    # received in its raw form - so any information won't be lost in a round
    # trip via TMail, or by bugs in it, and so we can use something other than
    # TMail at a later date. And so we can offer an option to download the
    # actual original mail sent by the authority in the admin interface (so
    # can check that attachment decoding failures are problems in the message,
    # not in our code). ]
    def self.receive(raw_email)
        logger.info "Received mail:\n #{raw_email}" unless logger.nil?
        mail = TMail::Mail.parse(raw_email)
        mail.base64_decode
        new.receive(mail, raw_email)
    end

    # Find which info requests the email is for
    def requests_matching_email(email)
        # We deliberately don't use Envelope-to here, so ones that are BCC
        # drop into the holding pen for checking.
        reply_info_requests = [] # XXX should be set?
        for address in (email.to || []) + (email.cc || [])
            reply_info_request = InfoRequest.find_by_incoming_email(address)
            reply_info_requests.push(reply_info_request) if reply_info_request
        end
        return reply_info_requests
    end

    # Member function, called on the new class made in self.receive above
    def receive(email, raw_email)
        # Find which info requests the email is for
        reply_info_requests = self.requests_matching_email(email)
        # Nothing found, so save in holding pen
        if reply_info_requests.size == 0 
            reason = _("Could not identify the request from the email address")
            request = InfoRequest.holding_pen_request
            request.receive(email, raw_email, false, reason)
            return
        end

        # Send the message to each request, to be archived with it
        for reply_info_request in reply_info_requests
            # If environment variable STOP_DUPLICATES is set, don't send message with same id again
            if ENV['STOP_DUPLICATES'] 
                if reply_info_request.already_received?(email, raw_email)
                    raise "message " + email.message_id + " already received by request"
                end
            end
            reply_info_request.receive(email, raw_email)
        end
    end

    # Send email alerts for overdue requests
    def self.alert_overdue_requests()
        info_requests = InfoRequest.find(:all, :conditions => [ "described_state = 'waiting_response' and awaiting_description = ?", false ], :include => [ :user ] )
        for info_request in info_requests
            alert_event_id = info_request.last_event_forming_initial_request.id
            # Only overdue requests
            if ['waiting_response_overdue', 'waiting_response_very_overdue'].include?(info_request.calculate_status)
                if info_request.calculate_status == 'waiting_response_overdue'
                    alert_type = 'overdue_1'
                elsif info_request.calculate_status == 'waiting_response_very_overdue'
                    alert_type = 'very_overdue_1'
                else
                    raise "unknown request status"
                end

                # For now, just to the user who created the request
                sent_already = UserInfoRequestSentAlert.find(:first, :conditions => [ "alert_type = ? and user_id = ? and info_request_id = ? and info_request_event_id = ?", alert_type, info_request.user_id, info_request.id, alert_event_id])
                if sent_already.nil?
                    # Alert not yet sent for this user, so send it
                    store_sent = UserInfoRequestSentAlert.new
                    store_sent.info_request = info_request
                    store_sent.user = info_request.user
                    store_sent.alert_type = alert_type
                    store_sent.info_request_event_id = alert_event_id
                    # Only send the alert if the user can act on it by making a followup
                    # (otherwise they are banned, and there is no point sending it)
                    if info_request.user.can_make_followup?
                        if info_request.calculate_status == 'waiting_response_overdue'
                            RequestMailer.deliver_overdue_alert(info_request, info_request.user)
                        elsif info_request.calculate_status == 'waiting_response_very_overdue'
                            RequestMailer.deliver_very_overdue_alert(info_request, info_request.user)
                        else
                            raise "unknown request status"
                        end
                    end
                    store_sent.save!
                end
            end
        end
    end

    # Send email alerts for new responses which haven't been classified. By default, 
    # it goes out 3 days after last update of event, then after 10, then after 24.
    def self.alert_new_response_reminders
        MySociety::Config.get("NEW_RESPONSE_REMINDER_AFTER_DAYS", [3, 10, 24]).each_with_index do |days, i|
            self.alert_new_response_reminders_internal(days, "new_response_reminder_#{i+1}")
        end
    end
    def self.alert_new_response_reminders_internal(days_since, type_code)
        info_requests = InfoRequest.find_old_unclassified(:order => 'info_requests.id', 
                                                          :include => [:user], 
                                                          :age_in_days => days_since)
        
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
                store_sent = UserInfoRequestSentAlert.new
                store_sent.info_request = info_request
                store_sent.user = info_request.user
                store_sent.alert_type = type_code
                store_sent.info_request_event_id = alert_event_id
                # XXX uses same template for reminder 1 and reminder 2 right now. 
                RequestMailer.deliver_new_response_reminder_alert(info_request, last_response_message)
                store_sent.save!
            end
        end
    end

    # Send email alerts for requests which need clarification. Goes out 3 days
    # after last update of event.
    def self.alert_not_clarified_request()
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
                store_sent = UserInfoRequestSentAlert.new
                store_sent.info_request = info_request
                store_sent.user = info_request.user
                store_sent.alert_type = 'not_clarified_1'
                store_sent.info_request_event_id = alert_event_id
                # Only send the alert if the user can act on it by making a followup
                # (otherwise they are banned, and there is no point sending it)
                if info_request.user.can_make_followup?
                    RequestMailer.deliver_not_clarified_alert(info_request, last_response_message)
                end
                store_sent.save!
            end
        end
    end

    # Send email alert to request submitter for new comments on the request.
    def self.alert_comment_on_request()
        
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
        
        info_requests = InfoRequest.find(:all,
            :conditions => [
               "info_requests.id in (
                    select info_request_id
                    from info_request_events
                    where event_type = 'comment'
                    and created_at > (now() - '1 month'::interval)
                )"
            ],
            :include => [ { :info_request_events => :user_info_request_sent_alerts } ],
            :order => "info_requests.id, info_request_events.created_at"
        )
        for info_request in info_requests

            # Count number of new comments to alert on
            earliest_unalerted_comment_event = nil
            last_comment_event = nil
            count = 0
            for e in info_request.info_request_events.reverse
                # alert on comments, which were not made by the user who originally made the request
                if e.event_type == 'comment' && e.comment.user_id != info_request.user_id
                    last_comment_event = e if last_comment_event.nil?

                    alerted_for = e.user_info_request_sent_alerts.find(:first, :conditions => [ "alert_type = 'comment_1' and user_id = ?", info_request.user_id])
                    if alerted_for.nil?
                        count = count + 1
                        earliest_unalerted_comment_event = e
                    else
                        break
                    end
                end
            end

            # Alert needs sending if there are new comments
            if count > 0
                store_sent = UserInfoRequestSentAlert.new
                store_sent.info_request = info_request
                store_sent.user = info_request.user
                store_sent.alert_type = 'comment_1'
                store_sent.info_request_event_id = last_comment_event.id
                if count > 1
                    RequestMailer.deliver_comment_on_alert_plural(info_request, count, earliest_unalerted_comment_event.comment)
                elsif count == 1
                    RequestMailer.deliver_comment_on_alert(info_request, last_comment_event.comment)
                else
                    raise "internal error"
                end
                store_sent.save!
            end
        end
    end


end


