# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.18 2007-11-22 15:22:35 francis Exp $

class RequestController < ApplicationController
    
    def show
        @info_request = InfoRequest.find(params[:id])
        @correspondences = @info_request.outgoing_messages + @info_request.incoming_messages
        @correspondences.sort! { |a,b| a.sent_at <=> b.sent_at } 
        @status = @info_request.calculate_status
    end

    def list
        @info_requests = InfoRequest.paginate :order => "created_at desc", :page => params[:page], :per_page => 25
    end
    
    def frontpage
    end

    # Form for creating new request
    def new
        # Read parameters in - public body can be passed from front page
        @info_request = InfoRequest.new(params[:info_request])
        @outgoing_message = OutgoingMessage.new(params[:outgoing_message])
    end

    # Page new form posts to
    def create
        # Create both FOI request and the first request message
        @info_request = InfoRequest.new(params[:info_request])
        @outgoing_message = OutgoingMessage.new(params[:outgoing_message].merge({ 
            :status => 'ready', 
            :message_type => 'initial_request'
        }))
        @info_request.outgoing_messages << @outgoing_message
        @outgoing_message.info_request = @info_request

        # This automatically saves dependent objects, such as @info_request, in the same transaction
        if not @info_request.valid?
            render :action => 'new'
        elsif authenticated?(
                :web => "To send your FOI request",
                :email => "Then your FOI request to " + @info_request.public_body.name + " will be sent.",
                :email_subject => "Confirm that you want to send an FOI request to " + @info_request.public_body.name
            )
            @info_request.user = authenticated_user
            @info_request.save
            @outgoing_message.send_message
            flash[:notice] = "Your Freedom of Information request has been created and sent on its way."
            redirect_to show_request_url(:id => @info_request)
        else
            # do nothing - as "authenticated?" has done the redirect to signin page for us
        end
    end

    # Did the incoming message contain info?
    def classify
        @incoming_message = IncomingMessage.find(params[:outgoing_message_id])
        @info_request = @incoming_message.info_request

        if authenticated_as_user?(@info_request.user,
                :web => "To view and classify the response to this FOI request",
                :email => "Then you can classify the FOI response you have got from " + @info_request.public_body.name + ".",
                :email_subject => "Classify a response from " + @info_request.public_body.name + " to your FOI request"
            )
            @correspondences = @info_request.outgoing_messages + @info_request.incoming_messages
            @correspondences.sort! { |a,b| a.sent_at <=> b.sent_at } 
            @status = @info_request.calculate_status
        else
            # do nothing - as "authenticated?" has done the redirect to signin page for us
        end

    end


   private

end
