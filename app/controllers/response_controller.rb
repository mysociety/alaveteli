# -*- encoding : utf-8 -*-
class ResponseController < ApplicationController
  before_filter :check_read_only,
                :set_incoming_message_and_last_request,
                :check_for_external_request,
                :check_user_credentials,
                :check_address,
                :check_request_matches_incoming_message,
                :set_params,
                :set_internal_review_ivars,
                :set_outgoing_message

  # Show an individual incoming message, and allow followup
  def show_response
    if !params[:submitted_followup].nil? && !params[:reedit]
      if @info_request.allow_new_responses_from == 'nobody'
        flash[:error] = _('Your follow up has not been sent because this request has been stopped to prevent spam. Please <a href="{{url}}">contact us</a> if you really want to send a follow up message.', :url => help_contact_path.html_safe)
      else
        if @info_request.find_existing_outgoing_message(params[:outgoing_message][:body])
          flash[:error] = _('You previously submitted that exact follow up message for this request.')
          render :action => 'show_response'
          return
        end

        # See if values were valid or not
        @outgoing_message.info_request = @info_request
        if !@outgoing_message.valid?
          render :action => 'show_response'
          return
        end
        if params[:preview].to_i == 1
          if @outgoing_message.what_doing == 'internal_review'
            @internal_review = true
          end
          render :action => 'followup_preview'
          return
        end

        # Send a follow up message
        @outgoing_message.sendable?

        mail_message = OutgoingMailer.followup(
          @outgoing_message.info_request,
          @outgoing_message,
          @outgoing_message.incoming_message_followup
        ).deliver

        @outgoing_message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id
        )

        @outgoing_message.save!

        if @outgoing_message.what_doing == 'internal_review'
          flash[:notice] = _("Your internal review request has been sent on its way.")
        else
          flash[:notice] = _("Your follow up message has been sent on its way.")
        end

        redirect_to request_url(@info_request)
      end
    else
      # render default show_response template
    end
  end

  private

  def check_address
    if !OutgoingMailer.is_followupable?(@info_request, @incoming_message)
      raise "unexpected followupable inconsistency" if @info_request.public_body.is_requestable?
      @reason = @info_request.public_body.not_requestable_reason
      render :action => 'followup_bad'
      return
    end
  end

  def check_for_external_request
    if @info_request.is_external?
      @reason = 'external'
      render :action => 'followup_bad'
      return
    end
  end

  def set_internal_review_ivars
    @internal_review = false
    @internal_review_pass_on = false
    if params[:internal_review]
      @internal_review = true
      @internal_review_pass_on = true
    end
  end

  def check_request_matches_incoming_message
    if @incoming_message and @info_request != @incoming_message.info_request
      raise ActiveRecord::RecordNotFound.
              new("Incoming message #{@incoming_message.id} does not belong " \
                    "to request #{@info_request.id}")
    end
  end

  def check_user_credentials
    # We want to make sure they're the right user first, before they start
    # writing a message and wasting their time if they are not the requester.
    params = get_login_params(@incoming_message, @info_request)
    return if !authenticated_as_user?(@info_request.user, params)
    if !authenticated_user.nil? && !authenticated_user.can_make_followup?
      @details = authenticated_user.can_fail_html
      render :template => 'user/banned'
      return
    end
    if !authenticated_user.nil? && !@info_request.user_can_view?(authenticated_user)
      return render_hidden
    end
  end

  def get_login_params(is_incoming, info_request)
    if is_incoming
      { :web => _("To send a follow up message to {{authority_name}}",
                  :authority_name => info_request.public_body.name),
        :email => _("Then you can write follow up message to {{authority_name}}.",
                    :authority_name => info_request.public_body.name),
        :email_subject => _("Write your FOI follow up message to {{authority_name}}",
                            :authority_name => info_request.public_body.name) }
    else
      { :web => _("To reply to {{authority_name}}.",
                  :authority_name => info_request.public_body.name),
        :email => _("Then you can write your reply to {{authority_name}}.",
                    :authority_name => info_request.public_body.name),
        :email_subject => _("Write a reply to {{authority_name}}",
                            :authority_name => info_request.public_body.name) }
    end
  end

  def outgoing_message_params
    params_outgoing_message = params[:outgoing_message] ? params[:outgoing_message].clone : {}
    params_outgoing_message.merge!({
                                     :status => 'ready',
                                     :message_type => 'followup',
                                     :incoming_message_followup => @incoming_message,
                                     :info_request_id => @info_request.id
    })
    params_outgoing_message[:what_doing] = 'internal_review' if @internal_review
    params_outgoing_message
  end

  def render_hidden(template='request/hidden')
    respond_to do |format|
      response_code = 403 # forbidden
      format.html{ render :template => template, :status => response_code }
      format.any{ render :nothing => true, :status => response_code }
    end
    false
  end

  def set_incoming_message
    if params[:incoming_message_id].nil?
      @incoming_message = nil
    else
      @incoming_message = IncomingMessage.find(params[:incoming_message_id])
    end
  end

  def set_info_request
    @info_request = InfoRequest.find(params[:id].to_i)
  end

  def set_last_request_data
    set_last_request(@info_request)
  end

  def set_outgoing_message
    outgoing_message_params
    @outgoing_message = OutgoingMessage.new(outgoing_message_params)
    @outgoing_message.set_signature_name(@user.name) if @user
  end

  def set_params
    @collapse_quotes = !params[:unfold]
    @is_owning_user = @info_request.is_owning_user?(authenticated_user)
    @gone_postal = params[:gone_postal]
    @gone_postal = false if !@is_owning_user
    set_postal_addresses if @gone_postal
  end

  def set_postal_addresses
    who_can_followup_to = @info_request.who_can_followup_to
    if who_can_followup_to.size == 0
      @postal_email = @info_request.request_email
      @postal_email_name = @info_request.name
    else
      @postal_email = who_can_followup_to[-1][1]
      @postal_email_name = who_can_followup_to[-1][0]
    end
  end
end
