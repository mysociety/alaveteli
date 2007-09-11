# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.6 2007-09-11 15:21:16 francis Exp $

class FileRequestController < ApplicationController
    def index
    end

    def create
        # Create both FOI request and the first request message
        @info_request = InfoRequest.new(params[:info_request])
        @outgoing_message = OutgoingMessage.new(params[:outgoing_message].merge({ 
            :status => 'ready', 
            :message_type => 'initial_request'
        }))

        # Save both models
        ActiveRecord::Base.transaction do
            begin
                @info_request.save!
                @outgoing_message.info_request_id = @info_request.id
                @outgoing_message.save!
                # render create action
            rescue ActiveRecord::RecordInvalid => e
                @outgoing_message.valid? # force cecking of errors even if info_request fails
                @outgoing_message.errors.full_messages.delete("info_request")
                render :action => 'index'
            end
        end
    end

end


