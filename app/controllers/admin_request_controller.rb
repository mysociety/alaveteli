# app/controllers/admin_request_controller.rb:
# Controller for viewing FOI requests from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: admin_request_controller.rb,v 1.19 2008-09-22 22:08:43 francis Exp $

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
            :conditions =>  @query.nil? ? nil : ["lower(title) like lower('%'||?||'%')", @query]
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

    def edit_comment
        @comment = Comment.find(params[:id])
    end

    def update_comment
        @comment = Comment.find(params[:id])

        old_body = @comment.body

        if @comment.update_attributes(params[:comment]) 
            @comment.info_request.log_event("edit_comment", 
                { :comment_if => @comment.id, :editor => admin_http_auth_user(), 
                    :old_body => old_body, :body => @comment.body })
            flash[:notice] = 'Comment successfully updated.'
            redirect_to request_admin_url(@comment.info_request)
        else
            render :action => 'edit_comment'
        end
    end 


    def destroy_incoming
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request = @incoming_message.info_request

        deleted_incoming_message = @incoming_message
        incoming_message_id = @incoming_message.id

        @incoming_message.fully_destroy
        @incoming_message.info_request.log_event("destroy_incoming", 
            { :editor => admin_http_auth_user(), :deleted_incoming_message => deleted_incoming_message })

        flash[:notice] = 'Incoming message successfully destroyed.'
        redirect_to request_admin_url(@info_request)
    end 

    def redeliver_incoming
        incoming_message = IncomingMessage.find(params[:redeliver_incoming_message_id])

        if params[:url_title].match(/^[0-9]+$/)
            destination_request = InfoRequest.find(params[:url_title].to_i)
        else
            destination_request = InfoRequest.find_by_url_title(params[:url_title])
        end

        if destination_request.nil?
            flash[:error] = "Failed to find destination request '" + params[:url_title] + "'"
            redirect_to request_admin_url(incoming_message.info_request)
        end

        raw_email_data = incoming_message.raw_email.data
        mail = TMail::Mail.parse(raw_email_data)
        mail.base64_decode
        destination_request.receive(mail, raw_email_data)

        incoming_message.fully_destroy

        flash[:notice] = "Message has been moved to this request"
        redirect_to request_admin_url(destination_request)
    end

    def generate_upload_url
        info_request = InfoRequest.find(params[:id])

        if params[:incoming_message_id]
            incoming_message = IncomingMessage.find(params[:incoming_message_id])
            email = incoming_message.mail.from_addrs[0].address
            name = incoming_message.safe_mail_from || info_request.public_body.name
        else
            email = info_request.public_body.request_email
            name = info_request.public_body.name
        end

        user = User.find_user_by_email(email)
        if not user
            user = User.new(:name => name, :email => email, :password => PostRedirect.generate_random_token)
            user.save!
        end

        if !info_request.public_body.is_foi_officer?(user)
            flash[:notice] = user.email + " is not an email at the domain @" + info_request.public_body.foi_officer_domain_required + ", so won't be able to upload."
            redirect_to request_admin_url(info_request)
            return
        end

        # Bejeeps, look, sometimes a URL is something that belongs in a model, jesus.
        # XXX hammer this square peg into the round MVC hole - should be calling main_url(upload_response_url())
        post_redirect = PostRedirect.new(
            :uri => upload_response_url(:url_title => info_request.url_title),
            :user_id => user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        flash[:notice] = 'Send "' + name + '" &lt;<a href="mailto:' + email + '">' + email + '</a>&gt; this URL: <a href="' + url + '">' + url + "</a> - it will log them in and let them upload a response to this request."
        redirect_to request_admin_url(info_request)
    end

    private

end
