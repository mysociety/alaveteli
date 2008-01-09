# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.33 2008-01-09 19:46:26 francis Exp $

class RequestController < ApplicationController
    
    def show
        @info_request = InfoRequest.find(params[:id])
        @correspondences = @info_request.incoming_messages + @info_request.info_request_events
        @correspondences.sort! { |a,b| a.sent_at <=> b.sent_at } 
        @status = @info_request.calculate_status
        @date_response_required_by = @info_request.date_response_required_by
        @collapse_quotes = params[:unfold] ? false : true
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
        # XXX this *should* also check outgoing message joined to is an initial request (rather than follow up)
        # XXX this check could go in the model, except we really want to pass @existing_request to the view so it can link to it.
        # XXX could have a date range here, so say only check last month's worth of new requests. If somebody is making
        # repeated requests, say once a quarter for time information, then might need to do that.
        @existing_request = InfoRequest.find(:first, :conditions => [ 'title = ? and public_body_id = ? and outgoing_messages.body = ?', params[:info_request][:title], params[:info_request][:public_body_id], params[:outgoing_message][:body] ], :include => [ :outgoing_messages ] )

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
                :email_subject => "Confirm that you want to send an FOI request to " + @info_request.public_body.name
            )
            @info_request.user = authenticated_user
            # This automatically saves dependent objects, such as @outgoing_message, in the same transaction
            @info_request.save!
            @outgoing_message.send_message
            flash[:notice] = "Your Freedom of Information request has been created and sent on its way."
            redirect_to show_request_url(:id => @info_request)
        else
            # do nothing - as "authenticated?" has done the redirect to signin page for us
        end
    end

    # Show an individual incoming message, and let the user classify it.
    def show_response
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request = @incoming_message.info_request
        @collapse_quotes = params[:unfold] ? false : true

        if @incoming_message.info_request_id != params[:id].to_i
            raise sprintf("Incoming message %d does not belong to request %d", @incoming_message.info_request_id, params[:id])
        end

        if params[:incoming_message]
            if not authenticated_as_user?(@info_request.user,
                    :web => "To view and classify the response to this FOI request",
                    :email => "Then you can classify the FOI response you have got from " + @info_request.public_body.name + ".",
                    :email_subject => "Classify a response from " + @info_request.public_body.name + " to your FOI request"
                )
                return
                # do nothing - as "authenticated?" has done the redirect to signin page for us
            end

            contains_information = (params[:incoming_message][:contains_information] == 'true' ? true : false)
            @incoming_message.contains_information = contains_information
            @incoming_message.user_classified = true
            @incoming_message.save!
            flash[:notice] = "Thank you for classifying the response."
            redirect_to show_request_url(:id => @info_request)
            return
        end
        if params[:commit]
            # Case when didn't choose radio option, but did submit form
            flash[:error] = "Please choose whether or not you got some of the information that you wanted."
        end
    end


   private

end
