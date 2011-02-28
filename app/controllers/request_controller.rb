# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.192 2009-10-19 19:26:40 francis Exp $

class RequestController < ApplicationController
    before_filter :check_read_only, :only => [ :new, :show_response, :describe_state, :upload_response ]
    protect_from_forgery :only => [ :new, :show_response, :describe_state, :upload_response ] # See ActionController::RequestForgeryProtection for details
    
    def show
        # Look up by old style numeric identifiers
        if params[:url_title].match(/^[0-9]+$/)
            @info_request = InfoRequest.find(params[:url_title].to_i)
            redirect_to request_url(@info_request)
            return
        end

        # Look up by new style text names 
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        if @info_request.nil?
            raise "Request not found" 
        end
        set_last_request(@info_request)

        # Test for whole request being hidden
        if !@info_request.user_can_view?(authenticated_user)
            render :template => 'request/hidden', :status => 410 # gone
            return
        end
       
        # Other parameters
        @info_request_events = @info_request.info_request_events
        @status = @info_request.calculate_status
        @collapse_quotes = params[:unfold] ? false : true
        @update_status = params[:update_status] ? true : false    
        @is_owning_user = @info_request.is_owning_user?(authenticated_user)
        @old_unclassified = @info_request.is_old_unclassified? && !authenticated_user.nil?
        
        if @update_status
            return if !@is_owning_user && !authenticated_as_user?(@info_request.user,
                    :web => "To update the status of this FOI request",
                    :email => "Then you can update the status of your request to " + @info_request.public_body.name + ".",
                    :email_subject => "Update the status of your request to " + @info_request.public_body.name
                )
        end
        
        @last_info_request_event_id = @info_request.last_event_id_needing_description
        @new_responses_count = @info_request.events_needing_description.select {|i| i.event_type == 'response'}.size

        # Sidebar stuff
        # ... requests that have similar imporant terms
        behavior_cache :tag => ['similar', @info_request.id] do
            begin
                limit = 10
                @xapian_similar = ::ActsAsXapian::Similar.new([InfoRequestEvent], @info_request.info_request_events, 
                  :limit => limit, :collapse_by_prefix => 'request_collapse')
                @xapian_similar_more = (@xapian_similar.matches_estimated > limit)
            rescue
                @xapian_similar = nil
            end
        end
     
        # Track corresponding to this page
        @track_thing = TrackThing.create_track_for_request(@info_request)
        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]

        # For send followup link at bottom
        @last_response = @info_request.get_last_response

        respond_to do |format|
            format.html { @has_json = true }
            format.json { render :json => @info_request.json_for_api(true) }
        end
    end

    # Extra info about a request, such as event history
    def details
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        if !@info_request.user_can_view?(authenticated_user)
            render :template => 'request/hidden', :status => 410 # gone
            return
        end

        @columns = ['id', 'event_type', 'created_at', 'described_state', 'last_described_at', 'calculated_state' ]
    end

    # Requests similar to this one
    def similar
        @per_page = 25
        @page = (params[:page] || "1").to_i
        @info_request = InfoRequest.find_by_url_title(params[:url_title])
        if !@info_request.user_can_view?(authenticated_user)
            render :template => 'request/hidden', :status => 410 # gone
            return
        end
        @xapian_object = ::ActsAsXapian::Similar.new([InfoRequestEvent], @info_request.info_request_events, 
            :offset => (@page - 1) * @per_page, :limit => @per_page, :collapse_by_prefix => 'request_collapse')
        
        if (@page > 1)
            @page_desc = " (page " + @page.to_s + ")" 
        else    
            @page_desc = ""
        end
    end

    def list
        @view = params[:view]

        if @view.nil?
            redirect_to request_list_url(:view => 'successful')
            return
        end

        if @view == 'recent'
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
        
        @page = get_search_page_from_params if !@page # used in cache case, as perform_search sets @page as side effect
        behavior_cache :tag => [@view, @page] do
            xapian_object = perform_search([InfoRequestEvent], query, sortby, 'request_collapse')
            @list_results = xapian_object.results.map { |r| r[:model] }
            @matches_estimated = xapian_object.matches_estimated
        end
        
        @title = @title + " (page " + @page.to_s + ")" if (@page > 1)

        @feed_autodetect = [ { :url => do_track_url(@track_thing, 'feed'), :title => @track_thing.params[:title_in_rss], :has_json => true } ]

        # Don't let robots go more than 20 pages in
        if @page > 20
            @no_crawl = true
        end
    end

    # Page new form posts to
    def new
        # All new requests are of normal_sort
        if !params[:outgoing_message].nil?
            params[:outgoing_message][:what_doing] = 'normal_sort'
        end

        # If we've just got here (so no writing to lose), and we're already
        # logged in, force the user to describe any undescribed requests. Allow
        # margin of 1 undescribed so it isn't too annoying - the function
        # get_undescribed_requests also allows one day since the response
        # arrived.
        if !@user.nil? && params[:submitted_new_request].nil? && !@user.can_leave_requests_undescribed?
            @undescribed_requests = @user.get_undescribed_requests 
            if @undescribed_requests.size > 1
                render :action => 'new_please_describe'
                return
            end
        end

        # Banned from making new requests?
        if !authenticated_user.nil? && !authenticated_user.can_file_requests?
            @details = authenticated_user.can_fail_html
            render :template => 'user/banned'
            return
        end

        # First time we get to the page, just display it
        if params[:submitted_new_request].nil? || params[:reedit]
            params[:info_request] = { } if !params[:info_request]

            # Read parameters in - first the public body (by URL name or id)
            if params[:url_name]
                if params[:url_name].match(/^[0-9]+$/)
                    params[:info_request][:public_body_id] = params[:url_name]
                else
                    public_body = PublicBody.find_by_url_name_with_historic(params[:url_name])
                    raise "None found" if public_body.nil? # XXX proper 404
                    params[:info_request][:public_body_id] = public_body.id
                end
            elsif params[:public_body_id]
                params[:info_request][:public_body_id] = params[:public_body_id]
            end
            if !params[:info_request][:public_body_id] 
                # compulsory to have a body by here, or go to front page which is start of process
                redirect_to frontpage_url
                return
            end

            # ... next any tags or other things
            params[:info_request][:title] = params[:title] if params[:title]
            params[:info_request][:tag_string] = params[:tags] if params[:tags]

            @info_request = InfoRequest.new(params[:info_request])
            params[:info_request_id] = @info_request.id
            params[:outgoing_message] = {} if !params[:outgoing_message]
            params[:outgoing_message][:body] = params[:body] if params[:body]
            params[:outgoing_message][:default_letter] = params[:default_letter] if params[:default_letter]
            params[:outgoing_message][:info_request] = @info_request
            @outgoing_message = OutgoingMessage.new(params[:outgoing_message])
            @outgoing_message.set_signature_name(@user.name) if !@user.nil?
            
            if @info_request.public_body.is_requestable?
                render :action => 'new'
            else
                if @info_request.public_body.not_requestable_reason == 'bad_contact'
                    render :action => 'new_bad_contact'
                else
                    # if not requestable because defunct or not_apply, redirect to main page
                    # (which doesn't link to the /new/ URL)
                    redirect_to public_body_url(@info_request.public_body)
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
        if !@info_request.public_body.is_requestable?
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
                if @user.nil? 
                    message += "<p>You do not need to include your email in the request in order to get a reply, as we will ask for it on the next screen (<a href=\"/help/privacy#email_address\">details</a>).</p>";
                else
                    message += "<p>You do not need to include your email in the request in order to get a reply (<a href=\"/help/privacy#email_address\">details</a>).</p>";
                end
                message += "<p>We recommend that you edit your request and remove the email address.
                If you leave it, the email address will be sent to the authority, but will not be displayed on the site.</p>"
            end
            if @outgoing_message.contains_postcode?
                message += "<p>Your request contains a <strong>postcode</strong>. Unless it directly relates to the subject of your request, please remove any address as it will <strong>appear publicly on the Internet</strong>.</p>";
            end
            if not message.empty?
                flash.now[:error] = message
            end
            render :action => 'preview'
            return
        end

        if !authenticated?(
                :web => "To send your FOI request",
                :email => "Then your FOI request to " + @info_request.public_body.name + " will be sent.",
                :email_subject => "Confirm your FOI request to " + @info_request.public_body.name
            )
            # do nothing - as "authenticated?" has done the redirect to signin page for us
            return
        end

        @info_request.user = authenticated_user
        # This automatically saves dependent objects, such as @outgoing_message, in the same transaction
        @info_request.save!
        # XXX send_message needs the database id, so we send after saving, which isn't ideal if the request broke here.
        @outgoing_message.send_message
        flash[:notice] = "<p>Your " + @info_request.law_used_full + " request has been <strong>sent on its way</strong>!</p>
            <p><strong>We will email you</strong> when there is a response, or after 20 working days if the authority still hasn't
            replied by then.</p>
            <p>If you write about this request (for example in a forum or a blog) please link to this page, and add an 
            annotation below telling people about your writing.</p>"
        redirect_to request_url(@info_request)
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

        @is_owning_user = @info_request.is_owning_user?(authenticated_user)       
        @last_info_request_event_id = @info_request.last_event_id_needing_description
        @old_unclassified = @info_request.is_old_unclassified? && !authenticated_user.nil?
        
        # Check authenticated, and parameters set. We check is_owning_user
        # to get admin overrides (see is_owning_user? above)
        if !@old_unclassified && !@is_owning_user && !authenticated_as_user?(@info_request.user,
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
        old_described_state = @info_request.described_state
        @info_request.set_described_state(params[:incoming_message][:described_state])
        
        # If you're not the *actual* requester owner. e.g. you are playing the
        # classification game, or you're doing this just because you are an
        # admin user (not because you also own the request).
        if !@info_request.is_actual_owning_user?(authenticated_user)
            # Log what you did, for classification game score purposes. We
            # don't log if you were the requester XXX This is presumably so you
            # don't score for classifying your own requests. Could instead
            # always log and filter at display time.
            @info_request.log_event("status_update", 
                { :user_id => authenticated_user.id, 
                  :old_described_state => old_described_state, 
                  :described_state => @info_request.described_state,
                })
            
            # Don't give advice on what to do next, as it isn't their request
            RequestMailer.deliver_old_unclassified_updated(@info_request)
            if session[:request_game] 
                flash[:notice] = 'Thank you for updating the status of the request \'<a href="' + CGI.escapeHTML(request_url(@info_request)) + '">' + CGI.escapeHTML(@info_request.title) + '</a>\'. There are some more requests below for you to classify.'
                redirect_to play_url 
            else
                flash[:notice] = 'Thank you for updating this request!'
                redirect_to request_url(@info_request)
            end
            return
        end

        # Display advice for requester on what to do next, as appropriate
        if @info_request.calculate_status == 'waiting_response'
            flash[:notice] = "<p>Thank you! Hopefully your wait isn't too long.</p> <p>By law, you should get a response promptly, and " + (@info_request.public_body.is_school? ? "in term time" : "") + " normally before the end of <strong>" + simple_date(@info_request.date_response_required_by) + "</strong>.</p>"
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'waiting_response_overdue'
            flash[:notice] = "<p>Thank you! Hope you don't have to wait much longer.</p> <p>By law, you should have got a response promptly, and " + (@info_request.public_body.is_school? ? "in term time" : "") + " normally before the end of <strong>" + simple_date(@info_request.date_response_required_by) + "</strong>.</p>"
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'waiting_response_very_overdue'
            flash[:notice] = "<p>Thank you! Your request is long overdue, by more than 40 working days. Most requests should be answered within 20 working days. You might like to complain about this, see below.</p>"
            redirect_to unhappy_url(@info_request)
        elsif @info_request.calculate_status == 'not_held'
            flash[:notice] = "<p>Thank you! Here are some ideas on what to do next:</p>
            <ul>
            <li>To send your request to another authority, first copy the text of your request below, then <a href=\"/new\">find the other authority</a>.</li>
            <li>If you would like to contest the authority's claim that they do not hold the information, here is 
            <a href=\"" + CGI.escapeHTML(unhappy_url(@info_request)) + "\">how to complain</a>.
            </li>
            <li>We have <a href=\"" + CGI.escapeHTML(unhappy_url(@info_request)) + "#other_means\">suggestions</a>
            on other means to answer your question.
            </li>
            </ul>
            "
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'rejected'
            flash[:notice] = "Oh no! Sorry to hear that your request was refused. Here is what to do now."
            redirect_to unhappy_url(@info_request)
        elsif @info_request.calculate_status == 'successful'
            flash[:notice] = "<p>We're glad you got all the information that you wanted. If you write about or make use of the information, please come back and add an annotation below saying what you did.</p><p>If you found WhatDoTheyKnow useful, <a href=\"http://www.mysociety.org/donate/\">make a donation</a> to the charity which runs it.</p>"
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'partially_successful'
            flash[:notice] = "<p>We're glad you got some of the information that you wanted. If you found WhatDoTheyKnow useful, <a href=\"http://www.mysociety.org/donate/\">make a donation</a> to the charity which runs it.</p><p>If you want to try and get the rest of the information, here's what to do now.</p>"
            redirect_to unhappy_url(@info_request)
        elsif @info_request.calculate_status == 'waiting_clarification'
            flash[:notice] = "Please write your follow up message containing the necessary clarifications below."
            redirect_to respond_to_last_url(@info_request)
        elsif @info_request.calculate_status == 'gone_postal'
            redirect_to respond_to_last_url(@info_request) + "?gone_postal=1"
        elsif @info_request.calculate_status == 'internal_review'
            flash[:notice] = "<p>Thank you! Hopefully your wait isn't too long.</p><p>You should get a response within 20 days, or be told if it will take longer (<a href=\"" + unhappy_url(@info_request) + "#internal_review\">details</a>).</p>"
            redirect_to request_url(@info_request)
        elsif @info_request.calculate_status == 'error_message'
            flash[:notice] = "<p>Thank you! We'll look into what happened and try and fix it up.</p><p>If the error was a delivery failure, and you can find an up to date FOI email address for the authority, please tell us using the form below.</p>"
            redirect_to help_general_url(:action => 'contact')
        elsif @info_request.calculate_status == 'requires_admin'
            flash[:notice] = "Please use the form below to tell us more."
            redirect_to help_general_url(:action => 'contact')
        elsif @info_request.calculate_status == 'user_withdrawn'
            flash[:notice] = "If you have not done so already, please write a message below telling the authority that you have withdrawn your request. Otherwise they will not know it has been withdrawn."
            redirect_to respond_to_last_url(@info_request)
        else
            raise "unknown calculate_status " + @info_request.calculate_status
        end
    end

    # Used for links from polymorphic URLs e.g. in Atom feeds - just redirect to 
    # proper URL for the message the event refers to
    def show_request_event
        @info_request_event = InfoRequestEvent.find(params[:info_request_event_id])
        if @info_request_event.is_incoming_message?
            redirect_to incoming_message_url(@info_request_event.incoming_message), :status => :moved_permanently
        elsif @info_request_event.is_outgoing_message?
            redirect_to outgoing_message_url(@info_request_event.outgoing_message), :status => :moved_permanently
        else
            # XXX maybe there are better URLs for some events than this
            redirect_to request_url(@info_request_event.info_request), :status => :moved_permanently 
        end 
    end

    # Show an individual incoming message, and allow followup
    def show_response
        # Banned from making new requests?
        if !authenticated_user.nil? && !authenticated_user.can_make_followup?
            @details = authenticated_user.can_fail_html
            render :template => 'user/banned'
            return
        end

        if params[:incoming_message_id].nil?
            @incoming_message = nil
        else
            @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        end

        @info_request = InfoRequest.find(params[:id].to_i)
        set_last_request(@info_request)

        @collapse_quotes = params[:unfold] ? false : true
        @is_owning_user = @info_request.is_owning_user?(authenticated_user)
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
            :incoming_message_followup => @incoming_message,
            :info_request_id => @info_request.id
        })
        @internal_review = false
        @internal_review_pass_on = false
        if !params[:internal_review].nil?
            params_outgoing_message[:what_doing] = 'internal_review'
            @internal_review = true
            @internal_review_pass_on = true
        end
        @outgoing_message = OutgoingMessage.new(params_outgoing_message)
        @outgoing_message.set_signature_name(@user.name) if !@user.nil?

        if (not @incoming_message.nil?) and @info_request != @incoming_message.info_request
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, @info_request.id)
        end

        # Test for hidden requests
        if !authenticated_user.nil? && !@info_request.user_can_view?(authenticated_user)
            render :template => 'request/hidden', :status => 410 # gone
            return
        end
 
        # Check address is good
        if !OutgoingMailer.is_followupable?(@info_request, @incoming_message)
            raise "unexpected followupable inconsistency" if @info_request.public_body.is_requestable?
            @reason = @info_request.public_body.not_requestable_reason
            render :action => 'followup_bad'
            return
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
            if @info_request.allow_new_responses_from == 'nobody'
                flash[:error] = 'Your follow up has not been sent because this request has been stopped to prevent spam. Please <a href="/help/contact">contact us</a> if you really want to send a follow up message.'
            else
                if @info_request.find_existing_outgoing_message(params[:outgoing_message][:body])
                    flash[:error] = 'You previously submitted that exact follow up message for this request.'
                    render :action => 'show_response'
                    return
                end

                # See if values were valid or not
                @outgoing_message.info_request = @info_request
                if !@outgoing_message.valid?
                    render :action => 'show_response'
                    return
                end
                if params[:preview].to_i == 1
                    if @outgoing_message.what_doing == 'internal_review'
                        @internal_review = true
                    end
                    render :action => 'followup_preview'
                    return
                end

                # Send a follow up message
                @outgoing_message.send_message
                @outgoing_message.save!
                if @outgoing_message.what_doing == 'internal_review'
                    flash[:notice] = "Your internal review request has been sent on its way."
                else
                    flash[:notice] = "Your follow up message has been sent on its way."
                end
                redirect_to request_url(@info_request)
            end
        else
            # render default show_response template
        end
    end

    # Download an attachment

    before_filter :authenticate_attachment, :only => [ :get_attachment, :get_attachment_as_html ]
    def authenticate_attachment
        # Test for hidden
        incoming_message = IncomingMessage.find(params[:incoming_message_id])
        if !incoming_message.info_request.user_can_view?(authenticated_user)
            render :template => 'request/hidden', :status => 410 # gone
        end
    end

    # special caching code so mime types are handled right
    around_filter :cache_attachments, :only => [ :get_attachment, :get_attachment_as_html ]
    def cache_attachments
        key = params.merge(:only_path => true)
        key_path = foi_fragment_cache_path(key)

        if foi_fragment_cache_exists?(key_path)
            cached = foi_fragment_cache_read(key_path)
            IncomingMessage # load global filename_to_mimetype XXX should move filename_to_mimetype to proper namespace
            response.content_type = filename_to_mimetype(params[:file_name].join("/")) or 'application/octet-stream'
            render_for_text(cached)
            return
        end

        yield

        # write it to the fileystem ourselves, so is just a plain file. (The
        # various fragment cache functions using Ruby Marshall to write the file
        # which adds a header, so isnt compatible with images that have been
        # extracted elsewhere from PDFs)
        foi_fragment_cache_write(key_path, response.body)
    end

    def get_attachment
        get_attachment_internal(false)

        # Prevent spam to magic request address. Note that the binary
        # subsitution method used depends on the content type
        @incoming_message.binary_mask_stuff!(@attachment.body, @attachment.content_type) 

        # we don't use @attachment.content_type here, as we want same mime type when cached in cache_attachments above
        response.content_type = filename_to_mimetype(params[:file_name].join("/")) or 'application/octet-stream'

        render :text => @attachment.body
    end

    def get_attachment_as_html
        get_attachment_internal(true)

        # images made during conversion (e.g. images in PDF files) are put in the cache directory, so
        # the same cache code in cache_attachments above will display them.
        key = params.merge(:only_path => true)
        key_path = foi_fragment_cache_path(key)
        image_dir = File.dirname(key_path)
        FileUtils.mkdir_p(image_dir)
        html, wrapper_id = @attachment.body_as_html(image_dir)

        view_html_stylesheet = render_to_string :partial => "request/view_html_stylesheet"
        html.sub!(/<head>/i, "<head>" + view_html_stylesheet)
        html.sub!(/<body[^>]*>/i, '<body><prefix-here><div id="' + wrapper_id + '"><div id="view_html_content">')
        html.sub!(/<\/body[^>]*>/i, '</div></div></body>')

        view_html_prefix = render_to_string :partial => "request/view_html_prefix"
        html.sub!("<prefix-here>", view_html_prefix)
        html.sub!("<attachment-url-here>", CGI.escape(@attachment_url))

        @incoming_message.html_mask_stuff!(html) 

        response.content_type = 'text/html'
        render :text => html
    end

    # Internal function
    def get_attachment_internal(html_conversion)
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request = @incoming_message.info_request
        if @incoming_message.info_request_id != params[:id].to_i
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, params[:id])
        end
        @part_number = params[:part].to_i
        @filename = params[:file_name].join("/")
        if html_conversion
            @original_filename = @filename.gsub(/\.html$/, "")
        else
            @original_filename = @filename
        end
       
        # check permissions
        raise "internal error, pre-auth filter should have caught this" if !@info_request.user_can_view?(authenticated_user)
  
        @attachment = IncomingMessage.get_attachment_by_url_part_number(@incoming_message.get_attachments_for_display, @part_number)
        raise "attachment not found part number " + @part_number.to_s + " incoming_message " + @incoming_message.id.to_s if @attachment.nil?

        # check filename in URL matches that in database (use a censor rule if you want to change a filename)
        raise "please use same filename as original file has, display: '" + @attachment.display_filename + "' old_display: '" + @attachment.old_display_filename + "' original: '" + @original_filename + "'" if @attachment.display_filename != @original_filename && @attachment.old_display_filename != @original_filename

        @attachment_url = get_attachment_url(:id => @incoming_message.info_request_id,
                :incoming_message_id => @incoming_message.id, :part => @part_number,
                :file_name => @original_filename )
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
            domain_required = @info_request.public_body.foi_officer_domain_required
            if domain_required.nil?
                render :template => 'user/wrong_user_unknown_email'
                return
            end
            @reason_params[:user_name] = "an email @" + domain_required
            render :template => 'user/wrong_user'
            return
        end

        if params[:submitted_upload_response]
            file_name = nil
            file_content = nil
            if !params[:file_1].nil?
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

