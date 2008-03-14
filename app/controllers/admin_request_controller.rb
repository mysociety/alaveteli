# app/controllers/admin_request_controller.rb:
# Controller for viewing FOI requests from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_request_controller.rb,v 1.8 2008-03-14 10:13:00 francis Exp $

class AdminRequestController < ApplicationController
    layout "admin"

    def index
        list
        render :action => 'list'
    end

    def list
        @query = params[:query]
        @info_requests = InfoRequest.paginate :order => "created_at desc", :page => params[:page], :per_page => 100,
            :conditions =>  @query.nil? ? nil : ["title ilike '%'||?||'%'", @query]
    end

    def show
        @info_request = InfoRequest.find(params[:id])
    end

    def resend
        @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
        @outgoing_message.resend_message
        flash[:notice] = "Outgoing message resent"
        redirect_to request_admin_url(@outgoing_message.info_request)
    end

    def edit
        @info_request = InfoRequest.find(params[:id])
    end

    def update
        @info_request = InfoRequest.find(params[:id])

        old_title = @info_request.title
        old_prominence = @info_request.prominence
        old_described_state = @info_request.described_state
        old_awaiting_description = @info_request.awaiting_description

        @info_request.title = params[:info_request][:title]
        @info_request.prominence = params[:info_request][:prominence]
        if @info_request.described_state != params[:info_request][:described_state]
            @info_request.set_described_state(params[:info_request][:described_state], @info_request.get_last_event.id.to_i)
        end
        @info_request.awaiting_description = params[:info_request][:awaiting_description] == "true" ? true : false

        if @info_request.valid?
            @info_request.save!
            @info_request.log_event("edit", 
                { :editor => admin_http_auth_user(), 
                    :old_title => old_title, :title => @info_request.title, 
                    :old_prominence => old_prominence, :prominence => @info_request.prominence, 
                    :old_described_state => old_described_state, :described_state => @info_request.described_state,
                    :old_awaiting_description => old_awaiting_description, :awaiting_description => @info_request.awaiting_description
                })
            flash[:notice] = 'Request successfully updated.'
            redirect_to request_admin_url(@info_request)
        else
            render :action => 'edit'
        end
    end 

    def edit_outgoing
        @outgoing_message = OutgoingMessage.find(params[:id])
    end

    def update_outgoing
        @outgoing_message = OutgoingMessage.find(params[:id])

        old_body = @outgoing_message.body

        if @outgoing_message.update_attributes(params[:outgoing_message]) 
            @outgoing_message.info_request.log_event("edit_outgoing", 
                { :outgoing_message_id => @outgoing_message.id, :editor => admin_http_auth_user(), 
                    :old_body => old_body, :body => @outgoing_message.body })
            flash[:notice] = 'Outgoing message successfully updated.'
            redirect_to request_admin_url(@outgoing_message.info_request)
        else
            render :action => 'edit_outgoing'
        end
    end 

    private

end
