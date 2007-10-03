# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.11 2007-10-03 17:13:50 francis Exp $

class FileRequestController < ApplicationController
    def index
        # render index.rhtml template
    end

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
            render :action => 'index'
        elsif check_authentication
            @info_request.save
        end

        # Save both models
#        valid = @info_request.valid? 
#        valid &&= @outgoing_message.valid? # XXX maybe there is a nicer way of preventing lazy boolean evaluation than this
#        if valid
#            if check_authentication
#                @info_request.save!
#                @outgoing_message.save!
#            end
#        else
#            render :action => 'index'
#        end
    end

end


