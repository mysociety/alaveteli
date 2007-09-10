# app/controllers/file_request_controller.rb:
# Interface for building a new FOI request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: file_request_controller.rb,v 1.5 2007-09-10 18:58:43 francis Exp $

class FileRequestController < ApplicationController
    def index
    end

    def create
        @info_request = InfoRequest.new(params[:info_request])
        @outgoing_message = OutgoingMessage.new(params[:outgoing_message].merge({ :status => 'ready',
            :message_type => 'initial_request'}))

        InfoRequest.transaction do
            @info_request.save!
            @outgoing_message.info_request_id = @info_request.id
            @outgoing_message.save!
            # render create action
        end
    rescue ActiveRecord::RecordInvalid => e
        @outgoing_message.valid? # force cecking of errors even if info_request fails
        render :action => 'index'
    end

end


