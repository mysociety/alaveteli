# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.130 2008-10-27 18:18:30 francis Exp $

class RequestController < ApplicationController
    
    def show
        # Look up by old style numeric identifiers
        if params[:url_title].match(/^[0-9]+$/)
            @info_request = InfoRequest.find(params[:url_title].to_i)
            redirect_to request_url(@info_request)
            return
        end

        # Look up by new style text names 
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        set_last_request(@info_request)
        
        # Other parameters
        @info_request_events = @info_request.info_request_events
        @status = @info_request.calculate_status
        @collapse_quotes = params[:unfold] ? false : true
        @is_owning_user = !authenticated_user.nil? && (authenticated_user.id == @info_request.user_id || authenticated_user.owns_every_request?)
        @events_needing_description = @info_request.events_needing_description
        last_event = @events_needing_description[-1]
        @last_info_request_event_id = last_event.nil? ? 0 : last_event.id
        @new_responses_count = @events_needing_description.select {|i| i.event_type == 'response'}.size

        # special case that an admin user can edit requires_admin requests
        @requires_admin_describe = (@info_request.described_state == 'requires_admin') && !authenticated_user.nil? && authenticated_user.requires_admin_power?

        # Sidebar stuff
        limit = 3
        # ... requests that have similar imporant terms
        @xapian_similar = ::ActsAsXapian::Similar.new([InfoRequestEvent], @info_request.info_request_events, 
            :limit => limit, :collapse_by_prefix => 'request_collapse')
        @xapian_similar_more = (@xapian_similar.matches_estimated > limit)
 
        # Track corresponding to this page
        @track_thing = TrackThing.create_track_for_request(@info_request)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]

        # For send followup link at bottom
        @last_response = @info_request.get_last_response
    end

    # Requests similar to this one
    def similar
        @per_page = 25
        @page = (params[:page] || "1").to_i
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        @xapian_object = ::ActsAsXapian::Similar.new([InfoRequestEvent], @info_request.info_request_events, 
            :offset => (@page - 1) * @per_page, :limit => @per_page, :collapse_by_prefix => 'request_collapse')
        
        # Stop robots crawling similar request lists. There is no point them
        # doing so. Google bot was going dozens of pages in, and they are slow
        # pages to generate, having an impact on server load.
        @no_crawl = true 

        if (@page > 1)
            @page_desc = " (page " + @page.to_s + ")" 
        else    
            @page_desc = ""
        end
    end

    def list
        @view = params[:view]

        if @view.nil?
            @title = "Recently sent Freedom of Information requests"
            query = "variety:sent";
            sortby = "newest"
            @track_thing = TrackThing.create_track_for_all_new_requests
        elsif @view == 'successful'
            @title = "Recently successful responses"
            query = 'variety:response (status:successful OR status:partially_successful)'
            sortby = "described"
            @track_thing = TrackThing.create_track_for_all_successful_requests
        else
            raise "unknown request list view " + @view.to_s
        end
        @xapian_object = perform_search([InfoRequestEvent], query, sortby, 'request_collapse')
        @title = @title + " (page " + @page.to_s + ")" if (@page > 1)

        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]
    end

    # Page new form posts to
    def new
        # If we've just got here (so no writing to lose), and we're already
        # logged in, force the user to describe any undescribed requests. Allow
        # margin of 1 undescribed so it isn't too annoying - the function
        # get_undescribed_requests also allows one day since the response
        # arrived.
        if !@user.nil? && params[:submitted_new_request].nil?
            @undescribed_requests = @user.get_undescribed_requests 
            @public_body = PublicBody.find(params[:public_body_id])
            if @undescribed_requests.size > 1
                render :action => 'new_please_describe'
                return
            end
        end

        # First time we get to the page, just display it
        if params[:submitted_new_request].nil? || params[:reedit]
            # Read parameters in - public body must be passed in
            if params[:public_body_id]
                params[:info_request] = { :public_body_id => params[:public_body_id] }
            end
            @info_request = InfoRequest.new(params[:info_request])
            @outgoing_message = OutgoingMessage.new(params[:outgoing_message])
            @outgoing_message.set_signature_name(@user.name) if !@user.nil?
            
            if @info_request.public_body.nil?
                redirect_to frontpage_url
            else 
                if @info_request.public_body.is_requestable?
                    render :action => 'new'
                else
                    render :action => 'new_' + @info_request.public_body.not_requestable_reason
                end
            end
            return
        end

        # See if the exact same request has already been submitted
        # XXX this check should theoretically be a validation rule in the
        # model, except we really want to pass @existing_request to the view so
        # it can link to it.
        @existing_request = InfoRequest.find_by_existing_request(params[:info_request][:title], params[:info_request][:public_body_id], params[:outgoing_message][:body])

        # Create both FOI request and the first request message
        @info_request = InfoRequest.new(params[:info_request])
        @outgoing_message = OutgoingMessage.new(params[:outgoing_message].merge({ 
            :status => 'ready', 
            :message_type => 'initial_request'
        }))
        @info_request.outgoing_messages << @outgoing_message
        @outgoing_message.info_request = @info_request

        # Maybe we lost the address while they're writing it
        if not @info_request.public_body.is_requestable?
            render :action => 'new_' + @info_request.public_body.not_requestable_reason
            return
        end

        # See if values were valid or not
        if !@existing_request.nil? || !@info_request.valid?
            # We don't want the error "Outgoing messages is invalid", as the outgoing message
            # will be valid for a specific reason which we are displaying anyway.
            @info_request.errors.delete("outgoing_messages")
            render :action => 'new'
            return
        end

        # Show preview page, if it is a preview
        if params[:preview].to_i == 1
            message = ""
            if @outgoing_message.contains_email?
                message += "<p>Your request contains an <strong>email address</strong>.</p><p>Unless the email directly relates to the subject of your request, you should remove it, as it will <strong>appear publicly on the Internet</strong>.</p>"
                if @user.nil? 
                    message += "<p>You do not need to include your email in order to get a reply, as we will ask for it on the next screen (<a href=\"/help/about#email_address\">details</a>).</p>";
                else
                    message += "<p>You do not need to include your email in order to get a reply (<a href=\"/help/about#email_address\">details</a>).</p>";
                end
            end
            if @outgoing_message.contains_postcode?
                message += "<p>Your request contains a <strong>postcode</strong>. Unless it directly relates to the subject of your request, please remove any address as it will <strong>appear publicly on the Internet</strong>.</p>";
            end
            if not message.empty?
                flash[:notice] = message
            end
            render :action => 'preview'
            return
        end

        if authenticated?(
                :web => "To send your FOI request",
                :email => "Then your FOI request to " + @info_request.public_body.name + " will be sent.",
                :email_subject => "Confirm your FOI request to " + @info_request.public_body.name
            )
            @info_request.user = authenticated_user
            # This automatically saves dependent objects, such as @outgoing_message, in the same transaction
            @info_request.save!
            # XXX send_message needs the database id, so we send after saving, which isn't ideal if the request broke here.
            @outgoing_message.send_message
            flash[:notice] = "Your " + @info_request.law_used_full + " request has been created and sent on its way!"
            redirect_to request_url(@info_request)
        else
            # do nothing - as "authenticated?" has done the redirect to signin page for us
        end
    end

    # Submitted to the describing state of messages form
    def describe_state
        @info_request = InfoRequest.find(params[:id].to_i)
        set_last_request(@info_request)

        # If this isn't a form submit, go to the request page
        if params[:submitted_describe_state].nil?
            redirect_to request_url(@info_request)
            return
        end

        # special case that an admin user can edit requires_admin requests
        @requires_admin_describe = (@info_request.described_state == 'requires_admin') && !authenticated_user.nil? && authenticated_user.requires_admin_power?

        if !@info_request.awaiting_description && !@requires_admin_describe
            flash[:notice] = "The status of this request is up to date."
            if !params[:submitted_describe_state].nil?
                flash[:notice] = "The status of this request was made up to date elsewhere while you were filling in the form."
            end
            redirect_to request_url(@info_request)
            return
        end

        @collapse_quotes = params[:unfold] ? false : true
        @events_needing_description = @info_request.events_needing_description
        last_event = @events_needing_description[-1]
        @last_info_request_event_id = last_event.nil? ? 0 : last_event.id
        @is_owning_user = !authenticated_user.nil? && (authenticated_user.id == @info_request.user_id || authenticated_user.owns_every_request?)
        @new_responses_count = @events_needing_description.select {|i| i.event_type == 'response'}.size

        # Check authenticated, and parameters set. We check is_owning_user
        # to get admin overrides (see owns_every_request? above)
        if !@is_owning_user && !authenticated_as_user?(@info_request.user,
                :web => "To classify the response to this FOI request",
                :email => "Then you can classify the FOI response you have got from " + @info_request.public_body.name + ".",
                :email_subject => "Classify an FOI response from " + @info_request.public_body.name
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end

        if !params[:incoming_message]
            flash[:error] = "Please choose whether or not you got some of the information that you wanted."
            redirect_to request_url(@info_request)
            return
        end

        if params[:last_info_request_event_id].to_i != @last_info_request_event_id
            flash[:error] = "The request has been updated since you originally loaded this page. Please check for any new incoming messages below, and try again."
            redirect_to request_url(@info_request)
            return
        end

        # Make the state change
        @info_request.set_described_state(params[:incoming_message][:described_state])

        # Display appropriate next page (e.g. help for complaint etc.)
        if @info_request.calculate_status == 'waiting_response'
            flash[:notice] = "<p>Thank you! Hopefully your wait isn't too long.</p> <p>By law, you should get a response before the end of <strong>" + simple_date(@info_request.date_response_required_by) + "</strong>.</p>"
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'waiting_response_overdue'
            flash[:notice] = "<p>Thank you! Hope you don't have to wait much longer.</p> <p>By law, you should have got a response before the end of <strong>" + simple_date(@info_request.date_response_required_by) + "</strong>.</p>"
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'not_held'
            flash[:notice] = "Thank you! You may want to send your request to another public authority. To do so, first copy the text of your request below, then <a href=\"/new\">find the other authority</a>."
            # XXX offer fancier option to duplicate request?
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'rejected'
            # XXX explain how to complain
            flash[:notice] = "Oh no! Sorry to hear that your request was rejected. Here is what to do now."
            redirect_to unhappy_url
        elsif @info_request.calculate_status == 'successful'
            flash[:notice] = "<p>We're glad you got all the information that you wanted. If you write about or make use of the information, please come back and add an annotation below saying what you did.</p><p>If you found WhatDoTheyKnow useful, <a href=\"http://www.mysociety.org/donate/\">make a donation</a> to the charity which runs it.</p>"
            # XXX quiz them here for a comment
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'partially_successful'
            flash[:notice] = "<p>We're glad you got some of the information that you wanted. We have details on what to do if you are <a href=\"/help/unhappy\">unhappy about the response you got</a>.</p><p>If you found WhatDoTheyKnow useful, <a href=\"http://www.mysociety.org/donate/\">make a donation</a> to the charity which runs it.</p>"
            # XXX explain how to complain / quiz them for a comment
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'waiting_clarification'
            flash[:notice] = "Please write your follow up message containing the necessary clarifications below."
            redirect_to show_response_url(:id => @info_request.id, :incoming_message_id => @events_needing_description[-1].params[:incoming_message_id])
        elsif @info_request.calculate_status == 'gone_postal'
            redirect_to respond_to_last_url(@info_request) + "?gone_postal=1"
        elsif @info_request.calculate_status == 'requires_admin'
            flash[:notice] = "Please use the form below if you would like to tell us what is unusual about the response."
            redirect_to help_general_url(:action => 'contact')
        else
            raise "unknown calculate_status " + @info_request.calculate_status
        end
    end

    # Used for links from polymorphic URLs e.g. in Atom feeds - just redirect to 
    # proper URL for the message the event refers to
    def show_request_event
        @info_request_event = InfoRequestEvent.find(params[:info_request_event_id])
        if not @info_request_event.incoming_message.nil?
            redirect_to incoming_message_url(@info_request_event.incoming_message)
        elsif not @info_request_event.outgoing_message.nil?
            redirect_to outgoing_message_url(@info_request_event.outgoing_message)
        else
            # XXX maybe there are better URLs for some events than this
            redirect_to request_url(@info_request_event.info_request)
        end 
    end

    # Show an individual incoming message, and allow followup
    def show_response
        if params[:incoming_message_id].nil?
            @incoming_message = nil
        else
            @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        end

        @info_request = InfoRequest.find(params[:id].to_i)
        set_last_request(@info_request)

        @collapse_quotes = params[:unfold] ? false : true
        @is_owning_user = !authenticated_user.nil? && (authenticated_user.id == @info_request.user_id || authenticated_user.owns_every_request?)
        @gone_postal = params[:gone_postal] ? true : false
        if !@is_owning_user
            @gone_postal = false
        end

        if @gone_postal
            who_can_followup_to = @info_request.who_can_followup_to
            if who_can_followup_to.size == 0
                @postal_email = @info_request.request_email
                @postal_email_name = @info_request.name
            else
                @postal_email = who_can_followup_to[-1][1]
                @postal_email_name = who_can_followup_to[-1][0]
            end
        end


        params_outgoing_message = params[:outgoing_message]
        if params_outgoing_message.nil?
            params_outgoing_message = {}
        end
        params_outgoing_message.merge!({ 
            :status => 'ready', 
            :message_type => 'followup',
            :incoming_message_followup => @incoming_message
        })
        @outgoing_message = OutgoingMessage.new(params_outgoing_message)
        @outgoing_message.set_signature_name(@user.name) if !@user.nil?

        if (not @incoming_message.nil?) and @info_request != @incoming_message.info_request
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, @info_request.id)
        end

        # Force login early - this is really the "send followup" form. We want
        # to make sure they're the right user first, before they start writing a
        # message and wasting their time if they are not the requester.
        if !authenticated_as_user?(@info_request.user,
                :web => @incoming_message.nil? ? 
                    "To send a follow up message to " + @info_request.public_body.name :
                    "To reply to " + @info_request.public_body.name,
                :email => @incoming_message.nil? ?
                    "Then you can write follow up message to " + @info_request.public_body.name + "." :
                    "Then you can write your reply to " + @info_request.public_body.name + ".",
                :email_subject => @incoming_message.nil? ?
                    "Write your FOI follow up message to " + @info_request.public_body.name :
                    "Write a reply to " + @info_request.public_body.name
            )
            return
        end

        if !params[:submitted_followup].nil? && !params[:reedit]
            if @info_request.stop_new_responses
                flash[:notice] = 'Your follow up has not been sent because this request has been stopped to prevent spam. Please <a href="/help/contact">contact us</a> if you really want to send a follow up message.'
            else
                # See if values were valid or not
                @outgoing_message.info_request = @info_request
                if !@outgoing_message.valid?
                    render :action => 'show_response'
                    return
                end
                if params[:preview].to_i == 1
                    render :action => 'followup_preview'
                    return
                end
                # Send a follow up message
                @outgoing_message.send_message
                @outgoing_message.save!
                flash[:notice] = "Your follow up message has been created and sent on its way."
                redirect_to request_url(@info_request)
            end
        else
            # render default show_response template
        end
    end

    # Download an attachment
    caches_page :get_attachment
    def get_attachment
        get_attachment_internal

        response.content_type = 'application/octet-stream'
        if !@attachment.content_type.nil?
            response.content_type = @attachment.content_type
        end
        render :text => @attachment.body
    end

    def get_attachment_as_html
        get_attachment_internal
        html = @attachment.body_as_html

        # Mask any more emails that have now been exposed (e.g. in PDFs - ones in
        # .doc will have been got in get_attachment_internal below)
        html = @incoming_message.binary_mask_stuff(html) 

        view_html_stylesheet = render_to_string :partial => "request/view_html_stylesheet"
        html.sub!(/<head>/i, "<head>" + view_html_stylesheet)
        html.sub!(/<body[^>]*>/i, '<body><prefix-here><div id="wrapper"><div id="view_html_content">' + view_html_stylesheet)
        html.sub!(/<\/body[^>]*>/i, '</div></div></body>' + view_html_stylesheet)

        view_html_prefix = render_to_string :partial => "request/view_html_prefix"
        html.sub!("<prefix-here>", view_html_prefix)

        response.content_type = 'text/html'
        render :text => html
    end

    # Internal function
    def get_attachment_internal
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request = @incoming_message.info_request
        if @incoming_message.info_request_id != params[:id].to_i
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, params[:id])
        end
        @part_number = params[:part].to_i
        @filename = params[:file_name]
        
        @attachment = IncomingMessage.get_attachment_by_url_part_number(@incoming_message.get_attachments_for_display, @part_number)

        # Prevent spam to magic request address.
        # XXX Bit dodgy modifying a binary like this but hey. Maybe only do for some mime types?
        @attachment.body = @incoming_message.binary_mask_stuff(@attachment.body) 
    end

    # FOI officers can upload a response
    def upload_response
        @info_request = InfoRequest.find_by_url_title(params[:url_title])

        @reason_params = {
                :web => "To upload a response, you must be logged in using an email address from " +  CGI.escapeHTML(@info_request.public_body.name),
                :email => "Then you can upload an FOI response. ",
                :email_subject => "Confirm your account on WhatDoTheyKnow.com"
        }
        if !authenticated?(@reason_params)
            return
        end

        if !@info_request.public_body.is_foi_officer?(@user)
            @reason_params[:user_name] = "an email @" + @info_request.public_body.foi_officer_domain_required
            render :template => 'user/wrong_user'
            return
        end

        if params[:submitted_upload_response]
            file_name = nil
            file_content = nil
            if params[:file_1].class.to_s == "ActionController::UploadedTempfile"
                file_name = params[:file_1].original_filename
                file_content = params[:file_1].read
            end
            body = params[:body] || ""

            if file_name.nil? && body.empty?
                flash[:error] = "Please type a message and/or choose a file containing your response."
                return
            end

            mail = RequestMailer.create_fake_response(@info_request, @user, body, file_name, file_content)
            @info_request.receive(mail, mail.encoded, true)
            flash[:notice] = "Thank you for responding to this FOI request! Your response has been published below, and a link to your response has been emailed to " + CGI.escapeHTML(@info_request.user.name) + "."
            redirect_to request_url(@info_request)
            return
        end
    end

end

