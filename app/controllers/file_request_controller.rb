# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.8 2007-09-12 15:56:18 francis Exp $

class FileRequestController < ApplicationController
    def index
        # render index.rhtml template
    end

#    before_filter :check_authentication, :only => [:create]
    def create
    
        # Create both FOI request and the first request message
        @info_request = InfoRequest.new(params[:info_request])
        @outgoing_message = OutgoingMessage.new(params[:outgoing_message].merge({ 
            :status => 'ready', 
            :message_type => 'initial_request'
        }))
        @outgoing_message.info_request = @info_request

        # Save both models
        valid = @info_request.valid? 
        valid &&= @outgoing_message.valid? # XXX maybe there is a nicer way of preventing lazy boolean evaluation than this
        if valid
            @info_request.save!
            @outgoing_message.save!
        else
            render :action => 'index'
        end
    end

end


