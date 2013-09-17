# app/controllers/admin_request_controller.rb:
# Controller for viewing FOI requests from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'ostruct'

class AdminRequestController < AdminController
    def index
        list
        render :action => 'list'
    end

    def list
        @query = params[:query]
        if @query
            info_requests = InfoRequest.where(["lower(title) like lower('%'||?||'%')", @query])
        else
            info_requests = InfoRequest
        end
        @info_requests = info_requests.paginate :order => "created_at desc",
                                              :page => params[:page],
                                              :per_page => 100
    end

    def show
        @info_request = InfoRequest.find(params[:id])
        # XXX is this *really* the only way to render a template to a
        # variable, rather than to the response?
        vars = OpenStruct.new(:name_to => @info_request.user_name,
                :name_from => AlaveteliConfiguration::contact_name,
                :info_request => @info_request, :reason => params[:reason],
                :info_request_url => 'http://' + AlaveteliConfiguration::domain + request_url(@info_request),
                :site_name => site_name)
        template = File.read(File.join(File.dirname(__FILE__), "..", "views", "admin_request", "hidden_user_explanation.html.erb"))
        @request_hidden_user_explanation = ERB.new(template).result(vars.instance_eval { binding })
    end

    def resend
        @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
        @outgoing_message.resend_message
        flash[:notice] = "Outgoing message resent"
        redirect_to admin_request_show_url(@outgoing_message.info_request)
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
        old_allow_new_responses_from = @info_request.allow_new_responses_from
        old_handle_rejected_responses = @info_request.handle_rejected_responses
        old_tag_string = @info_request.tag_string
        old_comments_allowed = @info_request.comments_allowed

        @info_request.title = params[:info_request][:title]
        @info_request.prominence = params[:info_request][:prominence]
        @info_request.awaiting_description = params[:info_request][:awaiting_description] == "true" ? true : false
        @info_request.allow_new_responses_from = params[:info_request][:allow_new_responses_from]
        @info_request.handle_rejected_responses = params[:info_request][:handle_rejected_responses]
        @info_request.tag_string = params[:info_request][:tag_string]
        @info_request.comments_allowed = params[:info_request][:comments_allowed] == "true" ? true : false

        if @info_request.valid?
            @info_request.save!
            @info_request.log_event("edit",
                { :editor => admin_current_user(),
                    :old_title => old_title, :title => @info_request.title,
                    :old_prominence => old_prominence, :prominence => @info_request.prominence,
                    :old_described_state => old_described_state, :described_state => params[:info_request][:described_state],
                    :old_awaiting_description => old_awaiting_description, :awaiting_description => @info_request.awaiting_description,
                    :old_allow_new_responses_from => old_allow_new_responses_from, :allow_new_responses_from => @info_request.allow_new_responses_from,
                    :old_handle_rejected_responses => old_handle_rejected_responses, :handle_rejected_responses => @info_request.handle_rejected_responses,
                    :old_tag_string => old_tag_string, :tag_string => @info_request.tag_string,
                    :old_comments_allowed => old_comments_allowed, :comments_allowed => @info_request.comments_allowed
                })
            if @info_request.described_state != params[:info_request][:described_state]
                @info_request.set_described_state(params[:info_request][:described_state])
            end
            # expire cached files
            expire_for_request(@info_request)
            flash[:notice] = 'Request successfully updated.'
            redirect_to admin_request_show_url(@info_request)
        else
            render :action => 'edit'
        end
    end

    def fully_destroy
        @info_request = InfoRequest.find(params[:id])

        user = @info_request.user
        url_title = @info_request.url_title

        @info_request.fully_destroy
        # expire cached files
        expire_for_request(@info_request)
        flash[:notice] = "Request #{url_title} has been completely destroyed. Email of user who made request: " + user.email
        redirect_to admin_request_list_url
    end

    def edit_comment
        @comment = Comment.find(params[:id])
    end

    def update_comment
        @comment = Comment.find(params[:id])

        old_body = @comment.body
        old_visible = @comment.visible
        @comment.visible = params[:comment][:visible] == "true" ? true : false

        if @comment.update_attributes(params[:comment])
            @comment.info_request.log_event("edit_comment",
                { :comment_id => @comment.id, :editor => admin_current_user(),
                    :old_body => old_body, :body => @comment.body,
                    :old_visible => old_visible, :visible => @comment.visible,
                })
            flash[:notice] = 'Comment successfully updated.'
            redirect_to admin_request_show_url(@comment.info_request)
        else
            render :action => 'edit_comment'
        end
    end

    # change user or public body of a request magically
    def move_request
        info_request = InfoRequest.find(params[:info_request_id])
        if params[:commit] == 'Move request to user' && !params[:user_url_name].blank?
            old_user = info_request.user
            destination_user = User.find_by_url_name(params[:user_url_name])
            if destination_user.nil?
                flash[:error] = "Couldn't find user '" + params[:user_url_name] + "'"
            else
                info_request.user = destination_user
                info_request.save!
                info_request.log_event("move_request", {
                        :editor => admin_current_user(),
                        :old_user_url_name => old_user.url_name,
                        :user_url_name => destination_user.url_name
                })

                info_request.reindex_request_events
                flash[:notice] = "Message has been moved to new user"
            end
            redirect_to admin_request_show_url(info_request)
        elsif params[:commit] == 'Move request to authority' && !params[:public_body_url_name].blank?
            old_public_body = info_request.public_body
            destination_public_body = PublicBody.find_by_url_name(params[:public_body_url_name])
            if destination_public_body.nil?
                flash[:error] = "Couldn't find public body '" + params[:public_body_url_name] + "'"
            else
                info_request.public_body = destination_public_body
                info_request.save!
                info_request.log_event("move_request", {
                        :editor => admin_current_user(),
                        :old_public_body_url_name => old_public_body.url_name,
                        :public_body_url_name => destination_public_body.url_name
                })

                info_request.reindex_request_events
                flash[:notice] = "Request has been moved to new body"
            end

            redirect_to admin_request_show_url(info_request)
        else
            flash[:error] = "Please enter the user or authority to move the request to"
            redirect_to admin_request_show_url(info_request)
        end
    end

    def generate_upload_url
        info_request = InfoRequest.find(params[:id])

        if params[:incoming_message_id]
            incoming_message = IncomingMessage.find(params[:incoming_message_id])
            email = incoming_message.from_email
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
            redirect_to admin_request_show_url(info_request)
            return
        end

        # Bejeeps, look, sometimes a URL is something that belongs in a controller, jesus.
        # XXX hammer this square peg into the round MVC hole
        post_redirect = PostRedirect.new(
            :uri => upload_response_url(:url_title => info_request.url_title),
            :user_id => user.id)
        post_redirect.save!
        url = confirm_url(:email_token => post_redirect.email_token)

        flash[:notice] = ("Send \"#{name}\" &lt;<a href=\"mailto:#{email}\">#{email}</a>&gt; this URL: <a href=\"#{url}\">#{url}</a> - it will log them in and let them upload a response to this request.").html_safe
        redirect_to admin_request_show_url(info_request)
    end

    def show_raw_email
        @raw_email = RawEmail.find(params[:id])
        # For the holding pen, try to guess where it should be ...
        @holding_pen = false
        if (@raw_email.incoming_message.info_request == InfoRequest.holding_pen_request && !@raw_email.incoming_message.empty_from_field?)
            @holding_pen = true

            # 1. Use domain of email to try and guess which public body it
            # is associated with, so we can display that.
            email = @raw_email.incoming_message.from_email
            domain = PublicBody.extract_domain_from_email(email)

            if domain.nil?
                @public_bodies = []
            else
                @public_bodies = PublicBody.find(:all, :order => "name",
                    :conditions => [ "lower(request_email) like lower('%'||?||'%')", domain ])
            end

            # 2. Match the email address in the message without matching the hash
            @info_requests =  InfoRequest.guess_by_incoming_email(@raw_email.incoming_message)

            # 3. Give a reason why it's in the holding pen
            last_event = InfoRequestEvent.find_by_incoming_message_id(@raw_email.incoming_message.id)
            @rejected_reason = last_event.params[:rejected_reason] || "unknown reason"
        end
    end

    def download_raw_email
        @raw_email = RawEmail.find(params[:id])

        response.content_type = 'message/rfc822'
        render :text => @raw_email.data
    end

    # used so due dates get fixed
    def mark_event_as_clarification
        info_request_event = InfoRequestEvent.find(params[:info_request_event_id])
        if info_request_event.event_type != 'response'
            raise Exception("can only mark responses as requires clarification")
        end
        info_request_event.described_state = 'waiting_clarification'
        info_request_event.calculated_state = 'waiting_clarification'
        # XXX deliberately don't update described_at so doesn't reenter search?
        info_request_event.save!

        flash[:notice] = "Old response marked as having been a clarification"
        redirect_to admin_request_show_url(info_request_event.info_request)
    end

    def hide_request
        ActiveRecord::Base.transaction do
            subject = params[:subject]
            explanation = params[:explanation]
            info_request = InfoRequest.find(params[:id])
            info_request.prominence = "requester_only"

            info_request.log_event("hide", {
                    :editor => admin_current_user(),
                    :reason => params[:reason],
                    :subject => subject,
                    :explanation => explanation
            })

            info_request.set_described_state(params[:reason])
            info_request.save!

            if ! info_request.is_external?
                ContactMailer.from_admin_message(
                        info_request.user,
                        subject,
                        params[:explanation].strip.html_safe
                    ).deliver
                flash[:notice] = _("Your message to {{recipient_user_name}} has been sent",:recipient_user_name=>CGI.escapeHTML(info_request.user.name))
            else
                flash[:notice] = _("This external request has been hidden")
            end
            # expire cached files
            expire_for_request(info_request)
            redirect_to admin_request_show_url(info_request)
        end
    end

    private

end
