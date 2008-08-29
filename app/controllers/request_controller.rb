# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.99 2008-08-29 12:58:08 francis Exp $

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
        
        # Other parameters
        @info_request_events = @info_request.info_request_events
        @status = @info_request.calculate_status
        @collapse_quotes = params[:unfold] ? false : true
        @is_owning_user = !authenticated_user.nil? && (authenticated_user.id == @info_request.user_id || authenticated_user.owns_every_request?)
        @events_needing_description = @info_request.events_needing_description
        last_event = @events_needing_description[-1]
        @last_info_request_event_id = last_event.nil? ? nil : last_event.id
        @new_responses_count = @events_needing_description.select {|i| i.event_type == 'response'}.size

        # Sidebar stuff
        limit = 3
        # ... requests that have similar imporant terms
        @xapian_similar = ::ActsAsXapian::Similar.new([InfoRequestEvent], @info_request.info_request_events, 
            :limit => limit, :collapse_by_prefix => 'request_collapse')
        @xapian_similar_more = (@xapian_similar.matches_estimated > limit)
 
        # Track corresponding to this page
        @track_thing = TrackThing.create_track_for_request(@info_request)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]

        # Default to subscribing to requests
        params[:subscribe_to_request] = true
    end

    # Requests similar to this one
    def similar
        @per_page = 25
        @page = (params[:page] || "1").to_i
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        @xapian_object = ::ActsAsXapian::Similar.new([InfoRequestEvent], @info_request.info_request_events, 
            :offset => (@page - 1) * @per_page, :limit => @per_page, :collapse_by_prefix => 'request_collapse')
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

        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss] } ]
    end

    # Page new form posts to
    def new
        # First time we get to the page, just display it
        if params[:submitted_new_request].nil? or params[:reedit]
            # Read parameters in - public body must be passed in
            if params[:public_body_id]
                params[:info_request] = { :public_body_id => params[:public_body_id] }
            end
            @info_request = InfoRequest.new(params[:info_request])
            @outgoing_message = OutgoingMessage.new(params[:outgoing_message])

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
                message += "Your request contains an <strong>email address</strong>. Unless it directly relates to the subject of your request, you should remove it, as it will <strong>appear publically on the Internet</strong>.";
            end
            if @outgoing_message.contains_postcode?
                if not message.empty?
                    message += "<br><br>"
                end
                message += "Your request contains a <strong>postcode</strong>. Unless it directly relates to the subject of your request, please remove any address as it will <strong>appear publically on the Internet</strong>.";
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

    # Describing state of messages post here
    def describe_state
        @info_request = InfoRequest.find(params[:id])

        if not @info_request.awaiting_description
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
        @last_info_request_event_id = last_event.nil? ? nil : last_event.id
        @is_owning_user = !authenticated_user.nil? && (authenticated_user.id == @info_request.user_id || authenticated_user.owns_every_request?)
        @new_responses_count = @events_needing_description.select {|i| i.event_type == 'response'}.size

        if @last_info_request_event_id.nil?
            flash[:notice] = "Internal error - awaiting description, but no event to describe"
            redirect_to request_url(@info_request)
            return
        end

        if !params[:submitted_describe_state].nil?
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
                return
            end
            
            if params[:last_info_request_event_id].to_i != @last_info_request_event_id
                flash[:error] = "The request has been updated since you originally loaded this page. Please check for any new incoming messages below, and try again."
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
                flash[:notice] = "Thank you! You may want to send your request to another public authority. To do so, first copy the text of your request below, then <a href=\"/new\">cick here</a> and find the other authority."
                # XXX offer fancier option to duplicate request?
                redirect_to request_url(@info_request)
            elsif @info_request.calculate_status == 'rejected'
                # XXX explain how to complain
                flash[:notice] = "Oh no! Sorry to hear that your request was rejected. Here is what to do now."
                redirect_to unhappy_url
            elsif @info_request.calculate_status == 'successful'
                flash[:notice] = "We're glad you got all the information that you wanted. Thank you for using WhatDoTheyKnow."
                # XXX quiz them here for a comment
                redirect_to request_url(@info_request)
            elsif @info_request.calculate_status == 'partially_successful'
                flash[:notice] = "We're glad you got some of the information that you wanted."
                # XXX explain how to complain / quiz them for a comment
                redirect_to request_url(@info_request)
            elsif @info_request.calculate_status == 'waiting_clarification'
                flash[:notice] = "Please write your follow up message containing the necessary clarifications below."
                redirect_to show_response_url(:id => @info_request.id, :incoming_message_id => @events_needing_description[-1].params[:incoming_message_id])
            elsif @info_request.calculate_status == 'requires_admin'
                flash[:notice] = "Thanks! The WhatDoTheyKnow team have been notified."
                redirect_to request_url(@info_request)
            else
                raise "unknown calculate_status " + @info_request.calculate_status
            end
            return
        else
            # Display default template
            return
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
        @collapse_quotes = params[:unfold] ? false : true
        @is_owning_user = !authenticated_user.nil? && (authenticated_user.id == @info_request.user_id || authenticated_user.owns_every_request?)

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

        if (not @incoming_message.nil?) and @info_request != @incoming_message.info_request
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, @info_request.id)
        end

        if !params[:submitted_followup].nil?
            if @info_request.stop_new_responses
                flash[:notice] = 'Your follow up has not been sent because this request has been stopped to prevent spam. Please <a href="/help/contact">contact us</a> if you really want to send a follow up message.'
            else
                # See if values were valid or not
                @outgoing_message.info_request = @info_request
                if !@outgoing_message.valid?
                    render :action => 'show_response'
                elsif authenticated_as_user?(@info_request.user,
                        :web => "To send your follow up message about your FOI request",
                        :email => "Then your follow up message to " + @info_request.public_body.name + " will be sent.",
                        :email_subject => "Confirm your FOI follow up message to " + @info_request.public_body.name
                    )
                    # Send a follow up message
                    @outgoing_message.send_message
                    @outgoing_message.save!
                    flash[:notice] = "Your follow up message has been created and sent on its way."
                    redirect_to request_url(@info_request)
                else
                    # do nothing - as "authenticated?" has done the redirect to signin page for us
                end
            end
        else
            # render default show_response template
        end
    end

    # Download an attachment
    def get_attachment
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request = @incoming_message.info_request
        if @incoming_message.info_request_id != params[:id].to_i
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, params[:id])
        end
        @part_number = params[:part].to_i
        
        @attachment = IncomingMessage.get_attachment_by_url_part_number(@incoming_message.get_attachments_for_display, @part_number)

        # Prevent spam to magic request address.
        # XXX Bit dodgy modifying a binary like this but hey. Maybe only do for some mime types?
        @attachment.body = @incoming_message.binary_mask_special_emails(@attachment.body) 

        response.content_type = 'application/octet-stream'
        if !@attachment.content_type.nil?
            response.content_type = @attachment.content_type
        end
        render :text => @attachment.body
    end

end

