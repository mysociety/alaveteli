# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.48 2008-02-14 09:57:56 francis Exp $

class RequestController < ApplicationController
    
    def show
        @info_request = InfoRequest.find(params[:id])
        @info_request_events = @info_request.info_request_events
        @info_request_events.sort! { |a,b| a.created_at <=> b.created_at } 
        @status = @info_request.calculate_status
        @collapse_quotes = params[:unfold] ? false : true
        @is_owning_user = !authenticated_user.nil? && authenticated_user.id == @info_request.user_id
        @events_needing_description = @info_request.events_needing_description
        last_event = @events_needing_description[-1]
        @last_info_request_event_id = last_event.nil? ? nil : last_event.id
        @new_responses_count = @events_needing_description.select {|i| i.event_type == 'response'}.size
    end

    def list
        @info_requests = InfoRequest.paginate :order => "created_at desc", :page => params[:page], :per_page => 25
    end
    
    def frontpage
    end

    # Page new form posts to
    def new
        # First time we get to the page, just display it
        if params[:submitted_new_request].nil?
            # Read parameters in - public body can be passed from front page
            @info_request = InfoRequest.new(params[:info_request])
            @outgoing_message = OutgoingMessage.new(params[:outgoing_message])
            render :action => 'new'
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

        # See if values were valid or not
        if !@existing_request.nil? || !@info_request.valid?
            # We don't want the error "Outgoing messages is invalid", as the outgoing message
            # will be valid for a specific reason which we are displaying anyway.
            @info_request.errors.delete("outgoing_messages")
            render :action => 'new'
        elsif authenticated?(
                :web => "To send your FOI request",
                :email => "Then your FOI request to " + @info_request.public_body.name + " will be sent.",
                :email_subject => "Confirm your FOI request to " + @info_request.public_body.name
            )
            @info_request.user = authenticated_user
            # This automatically saves dependent objects, such as @outgoing_message, in the same transaction
            @info_request.save!
            # XXX send_message needs the database id, so we send after saving, which isn't ideal if the request broke here.
            @outgoing_message.send_message
            flash[:notice] = "Your Freedom of Information request has been created and sent on its way."
            redirect_to show_request_url(:id => @info_request)
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
            redirect_to show_request_url(:id => @info_request)
            return
        end

        @events_needing_description = @info_request.events_needing_description
        last_event = @events_needing_description[-1]
        @last_info_request_event_id = last_event.nil? ? nil : last_event.id
        @is_owning_user = !authenticated_user.nil? && authenticated_user.id == @info_request.user_id
        @new_responses_count = @events_needing_description.select {|i| i.event_type == 'response'}.size

        if @last_info_request_event_id.nil?
            raise "mnoo " + @events_needing_description.size.to_s
            flash[:notice] = "Internal error - awaiting description, but no event to describe"
            redirect_to show_request_url(:id => @info_request)
            return
        end

        if !params[:submitted_describe_state].nil?
            # Check authenticated, and parameters set
            
            if not authenticated_as_user?(@info_request.user,
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
            @info_request.set_described_state(params[:incoming_message][:described_state], @last_info_request_event_id)

            # Display appropriate next page (e.g. help for complaint etc.)
            if @info_request.described_state == 'waiting_response'
                flash[:notice] = "<p>Thank you! Hopefully your wait isn't too long.</p> <p>By law, you should get a response before the end of <strong>" + simple_date(@info_request.date_response_required_by) + "</strong>.</p>"
                redirect_to show_request_url(:id => @info_request)
            elsif @info_request.described_state == 'rejected'
                # XXX explain how to complain
                flash[:notice] = "Oh no! Sorry to hear that your request was rejected. Here is what to do now."
                redirect_to unhappy_url
            elsif @info_request.described_state == 'successful'
                flash[:notice] = "We're glad you got all the information that you wanted. Thank you for using GovernmentSpy."
                # XXX quiz them here for a comment
                redirect_to show_request_url(:id => @info_request)
            elsif @info_request.described_state == 'partially_successful'
                flash[:notice] = "We're glad you got some of the information that you wanted."
                # XXX explain how to complain / quiz them for a comment
                redirect_to show_request_url(:id => @info_request)
            elsif @info_request.described_state == 'waiting_clarification'
                flash[:notice] = "Please write your follow up message containing the necessary clarifications below."
                redirect_to show_response_url(:id => @info_request.id, :incoming_message_id => @events_needing_description[-1].params[:incoming_message_id])
            else
                raise "unknown described_state " + @info_request.described_state
            end
            return
        else
            # Display default template
            return
        end
    end


    # Show an individual incoming message, and allow followup
    def show_response
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request = @incoming_message.info_request
        @collapse_quotes = params[:unfold] ? false : true
        @is_owning_user = !authenticated_user.nil? && authenticated_user.id == @info_request.user_id

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

        if @incoming_message.info_request_id != params[:id].to_i
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, params[:id])
        end

        if !params[:submitted_followup].nil?
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
                redirect_to show_request_url(:id => @info_request)
            else
                # do nothing - as "authenticated?" has done the redirect to signin page for us
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
        response.content_type = 'application/octet-stream'
        if !@attachment.content_type.nil?
            response.content_type = @attachment.content_type
        end
        render :text => @attachment.body
    end

    private
end
