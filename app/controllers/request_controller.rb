# app/controllers/request_controller.rb:
# Show information about one particular request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: request_controller.rb,v 1.11 2007-11-01 05:44:43 francis Exp $

class RequestController < ApplicationController
    
    def show
        @info_request = InfoRequest.find(params[:id])
        @correspondences = @info_request.outgoing_messages + @info_request.incoming_messages
        @correspondences.sort! { |a,b| a.sent_at <=> b.sent_at } 
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
        elsif authenticated?
            @info_request.user = authenticated_user
            @info_request.save
            @outgoing_message.send_message
            flash[:notice] = "Your Freedom of Information request has been created and sent on its way."
            redirect_to show_request_url(:id => @info_request)
        else
            # do nothing - as "authenticated?" has done the redirect to signin page for us
        end

        # Save both models # XXX still fiddling with error reporting here, see Louise's
        # email about some better error reporting plugin.
#        valid = @info_request.valid? 
#        valid &&= @outgoing_message.valid? # XXX maybe there is a nicer way of preventing lazy boolean evaluation than this
#        if valid
#            if authenticated?
#                @info_request.save!
#                @outgoing_message.save!
#            end
#        else
#            render :action => 'index'
#        end
    end

    private

end
