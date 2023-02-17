# app/controllers/admin_request_controller.rb:
# Controller for viewing FOI requests from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminRequestController < AdminController

  before_action :set_info_request, :check_info_request, only: %i[
    show edit update destroy move generate_upload_url hide
  ]

  def index
    @query = params[:query]
    if @query
      info_requests = InfoRequest.where(["lower(title) like lower('%'||?||'%')", @query])
    else
      info_requests = InfoRequest
    end

    if cannot? :admin, AlaveteliPro::Embargo
      info_requests = info_requests.not_embargoed
    end

    @info_requests = info_requests.order(created_at: :desc).paginate(
      page: params[:page],
      per_page: 100)
  end

  def show
  end

  def edit
  end

  def update
    old_title = @info_request.title
    old_prominence = @info_request.prominence
    old_prominence_reason = @info_request.prominence_reason
    old_described_state = @info_request.described_state
    old_awaiting_description = @info_request.awaiting_description
    old_allow_new_responses_from = @info_request.allow_new_responses_from
    old_handle_rejected_responses = @info_request.handle_rejected_responses
    old_tag_string = @info_request.tag_string
    old_comments_allowed = @info_request.comments_allowed


    if @info_request.update(info_request_params)
      @info_request.log_event(
        'edit',
        editor: admin_current_user,
        old_title: old_title,
        title: @info_request.title,
        old_prominence: old_prominence,
        prominence: @info_request.prominence,
        old_prominence_reason: old_prominence_reason,
        prominence_reason: @info_request.prominence_reason,
        old_described_state: old_described_state,
        described_state: params[:info_request][:described_state],
        old_awaiting_description: old_awaiting_description,
        awaiting_description: @info_request.awaiting_description,
        old_allow_new_responses_from: old_allow_new_responses_from,
        allow_new_responses_from: @info_request.allow_new_responses_from,
        old_handle_rejected_responses: old_handle_rejected_responses,
        handle_rejected_responses: @info_request.handle_rejected_responses,
        old_tag_string: old_tag_string,
        tag_string: @info_request.tag_string,
        old_comments_allowed: old_comments_allowed,
        comments_allowed: @info_request.comments_allowed
      )
      if @info_request.described_state != params[:info_request][:described_state]
        @info_request.set_described_state(params[:info_request][:described_state])
      end
      # expire cached files
      @info_request.expire
      flash[:notice] = 'Request successfully updated.'
      redirect_to admin_request_url(@info_request)
    else
      render action: 'edit'
    end
  end

  def destroy
    user = @info_request.user
    url_title = @info_request.url_title

    @info_request.destroy

    email = user.try(:email) ? user.email : 'This request is external so has no associated user'
    flash[:notice] = "Request #{ url_title } has been completely destroyed. Email of user who made request: #{ email }"
    redirect_to admin_requests_url
  end

  # change user or public body of a request magically
  def move
    editor = admin_current_user

    if params[:commit] == 'Move request to user' && !params[:user_url_name].blank?
      destination_user = User.find_by_url_name(params[:user_url_name])

      if @info_request.move_to_user(destination_user, editor: editor)
        flash[:notice] = "Message has been moved to new user"
      else
        flash[:error] = "Couldn't find user '#{params[:user_url_name]}'"
      end

      redirect_to admin_request_url(@info_request)
    elsif params[:commit] == 'Move request to authority' && !params[:public_body_url_name].blank?
      destination_body = PublicBody.find_by_url_name(
        params[:public_body_url_name]
      )

      if @info_request.move_to_public_body(destination_body, editor: editor)
        flash[:notice] = "Request has been moved to new body"
      else
        flash[:error] = "Couldn't find public body '#{ params[:public_body_url_name] }'"
      end

      redirect_to admin_request_url(@info_request)
    else
      flash[:error] = "Please enter the user or authority to move the request to"
      redirect_to admin_request_url(@info_request)
    end
  end

  def generate_upload_url
    if params[:incoming_message_id]
      incoming_message = IncomingMessage.find(params[:incoming_message_id])
      email = incoming_message.from_email
      name = incoming_message.safe_from_name || @info_request.public_body.name
    else
      email = @info_request.public_body.request_email
      name = @info_request.public_body.name
    end

    user = User.find_user_by_email(email)
    unless user
      user = User.new(name: name, email: email, password: PostRedirect.generate_random_token)
      user.save!
    end

    unless @info_request.public_body.is_foi_officer?(user)
      flash[:notice] = user.email + " is not an email at the domain @" + @info_request.public_body.foi_officer_domain_required + ", so won't be able to upload."
      redirect_to admin_request_url(@info_request)
      return
    end

    # Bejeeps, look, sometimes a URL is something that belongs in a controller, jesus.
    # TODO: hammer this square peg into the round MVC hole
    post_redirect = PostRedirect.new(
      uri: upload_response_url(url_title: @info_request.url_title),
    user_id: user.id)
    post_redirect.save!

    flash[:notice] = {
      partial: "upload_email_message",
      locals: {
        name: name,
        email: email,
        url: confirm_url(email_token: post_redirect.email_token)
      }
    }
    redirect_to admin_request_url(@info_request)
  end

  def hide
    ActiveRecord::Base.transaction do
      subject = params[:subject]
      explanation = params[:explanation]

      old_prominence = @info_request.prominence
      old_prominence_reason = @info_request.prominence_reason
      @info_request.prominence = "requester_only"
      @info_request.prominence_reason = params[:prominence_reason]

      @info_request.log_event(
        'hide',
        editor: admin_current_user,
        reason: params[:reason],
        subject: subject,
        explanation: explanation,
        old_prominence: old_prominence,
        prominence: @info_request.prominence,
        old_prominence_reason: old_prominence_reason,
        prominence_reason: @info_request.prominence_reason
      )

      @info_request.set_described_state(params[:reason])
      @info_request.save!

      if ! @info_request.is_external?
        ContactMailer.from_admin_message(
          @info_request.user.name,
          @info_request.user.email,
          subject,
          params[:explanation].strip.html_safe
        ).deliver_now
        flash[:notice] = _("Your message to {{recipient_user_name}} has " \
                           "been sent",
                           recipient_user_name: @info_request.user.
                                                     name.html_safe)
      else
        flash[:notice] = _("This external request has been hidden")
      end
      # expire cached files
      @info_request.expire
      redirect_to admin_request_url(@info_request)
    end
  end

  private

  def info_request_params
    if params[:info_request]
      params.require(:info_request).permit(:title,
                                           :prominence,
                                           :prominence_reason,
                                           :described_state,
                                           :awaiting_description,
                                           :allow_new_responses_from,
                                           :handle_rejected_responses,
                                           :tag_string,
                                           :comments_allowed)
    else
      {}
    end
  end

  def set_info_request
    @info_request = InfoRequest.find(params[:id].to_i)
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
