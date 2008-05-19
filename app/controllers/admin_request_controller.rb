# app/controllers/admin_request_controller.rb:
# Controller for viewing FOI requests from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_request_controller.rb,v 1.13 2008-05-19 12:01:21 francis Exp $

class AdminRequestController < ApplicationController
    layout "admin"
    before_filter :assign_http_auth_user

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
        old_stop_new_responses = @info_request.stop_new_responses

        @info_request.title = params[:info_request][:title]
        @info_request.prominence = params[:info_request][:prominence]
        if @info_request.described_state != params[:info_request][:described_state]
            @info_request.set_described_state(params[:info_request][:described_state])
        end
        @info_request.awaiting_description = params[:info_request][:awaiting_description] == "true" ? true : false
        @info_request.stop_new_responses = params[:info_request][:stop_new_responses] == "true" ? true : false

        if @info_request.valid?
            @info_request.save!
            @info_request.log_event("edit", 
                { :editor => admin_http_auth_user(), 
                    :old_title => old_title, :title => @info_request.title, 
                    :old_prominence => old_prominence, :prominence => @info_request.prominence, 
                    :old_described_state => old_described_state, :described_state => @info_request.described_state,
                    :old_awaiting_description => old_awaiting_description, :awaiting_description => @info_request.awaiting_description,
                    :old_stop_new_responses => old_stop_new_responses, :stop_new_responses => @info_request.stop_new_responses
                })
            flash[:notice] = 'Request successfully updated.'
            redirect_to request_admin_url(@info_request)
        else
            render :action => 'edit'
        end
    end 

    def fully_destroy
        @info_request = InfoRequest.find(params[:id])

        user = @info_request.user
        url_title = @info_request.url_title

        @info_request.fully_destroy

        flash[:notice] = "Request #{url_title} has been completely destroyed. Email of user who made request: " + user.email
        redirect_to admin_url('request/list')
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

    def destroy_incoming
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request_event = InfoRequestEvent.find_by_incoming_message_id(@incoming_message.id)
        @info_request = @incoming_message.info_request

        raw_data = @incoming_message
        incoming_message_id = @incoming_message.id

        ActiveRecord::Base.transaction do
            @info_request_event.track_things_sent_emails.each { |a| a.destroy }
            @info_request_event.user_info_request_sent_alerts.each { |a| a.destroy }
            @info_request_event.destroy
            @incoming_message.destroy
        end

        @incoming_message.info_request.log_event("destroy_incoming", 
            { :editor => admin_http_auth_user(), :raw_data => raw_data })

        flash[:notice] = 'Incoming message successfully destroyed.'
        redirect_to request_admin_url(@info_request)
    end 

    private

end
