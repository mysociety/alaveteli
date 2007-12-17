# app/controllers/admin_request_controller.rb:
# Controller for editing public bodies from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_request_controller.rb,v 1.1 2007-12-17 00:34:55 francis Exp $

class AdminRequestController < ApplicationController
    layout "admin"

    def index
        list
        render :action => 'list'
    end

    def list
        @info_requests = InfoRequest.paginate :order => "created_at desc", :page => params[:page], :per_page => 100
    end

    def show
        @info_request = InfoRequest.find(params[:id])
    end

    def resend
        @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
        @outgoing_message.resend_message
        flash[:notice] = "Outgoing message resent"
        redirect_to admin_url('request/show/' + @outgoing_message.info_request.id.to_s)
    end

#    def destroy
#        InfoRequest.find(params[:id]).destroy
#        redirect_to admin_url('request/list')
#    end

    private

end
