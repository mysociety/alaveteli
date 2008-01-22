# app/controllers/admin_request_controller.rb:
# Controller for viewing FOI requests from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_request_controller.rb,v 1.3 2008-01-22 18:34:15 francis Exp $

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

    def edit_outgoing
        @outgoing_message = OutgoingMessage.find(params[:id])
    end

    def update_outgoing
        @outgoing_message = OutgoingMessage.find(params[:id])
        old_body = @outgoing_message.body
        if @outgoing_message.update_attributes(params[:outgoing_message])
            @outgoing_message.info_request.log_event("edit_outgoing", { :outgoing_message_id => @outgoing_message.id, :editor => admin_http_auth_user(), :old_body => old_body, :body => @outgoing_message.body })
            flash[:notice] = 'OutgoingMessage was successfully updated.'
            redirect_to admin_url('request/show/' + @outgoing_message.info_request.id.to_s)
        else
            render :action => 'edit_outgoing'
        end
    end 

    private

end
