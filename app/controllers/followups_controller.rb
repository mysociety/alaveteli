# -*- encoding : utf-8 -*-
class FollowupsController < ApplicationController
  before_action :check_read_only,
                :set_incoming_message,
                :set_info_request,
                :set_last_request_data,
                :check_can_followup,
                :check_user_credentials,
                :check_request_matches_incoming_message,
                :set_params,
                :set_internal_review,
                :set_outgoing_message,
                :set_refusal_advice,
                :set_in_pro_area

  before_action :check_reedit, :only => [:preview, :create]

  before_action :check_responses_allowed, :only => [:create]

  def new
  end

  def create
    @outgoing_message.info_request = @info_request
    if @info_request.find_existing_outgoing_message(params[:outgoing_message][:body])
      flash.clear # otherwise the message sent notice may be redisplayed
      flash[:error] = _('You previously submitted that exact follow up message for this request.')
    elsif @outgoing_message.valid?
      send_followup
      redirect_to request_url(@info_request) and return
    end
    render :action => 'new'
  end

  def preview
    @outgoing_message.info_request = @info_request
    if @outgoing_message.what_doing == 'internal_review'
       @internal_review = true
    end
    unless @outgoing_message.valid?
      render :action => 'new'
      return
    end
  end

  private

  def check_can_followup
    unless @info_request.is_followupable?(@incoming_message)
      @reason = @info_request.followup_bad_reason
      render :action => 'followup_bad'
      return
    end
  end

  def set_internal_review
    @internal_review = false
    if params[:internal_review]
      @internal_review = true
    end
  end

  def check_reedit
    if params[:reedit]
      render :action => 'new'
      return
    end
  end

  def check_request_matches_incoming_message
    if @incoming_message and @info_request != @incoming_message.info_request
      raise ActiveRecord::RecordNotFound.
              new("Incoming message #{@incoming_message.id} does not belong " \
                    "to request #{@info_request.id}")
    end
  end

  def check_responses_allowed
    if @info_request.allow_new_responses_from == "nobody"
      flash.now[:error] = { :partial => "followup_not_sent.html.erb",
                            :locals => {
                            :help_contact_path => help_contact_path } }
      render :action => 'new'
      return
    end
  end

  def check_user_credentials
    # We want to make sure they're the right user first, before they start
    # writing a message and wasting their time if they are not the requester.
    params = get_login_params(@incoming_message, @info_request)
    return if !authenticated_as_user?(@info_request.user, params)
    if authenticated_user and !authenticated_user.can_make_followup?
      @details = authenticated_user.can_fail_html
      render :template => 'user/banned'
      return
    end
    if authenticated_user && cannot?(:read, @info_request)
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
    params_outgoing_message = params_to_unsafe_hash(params[:outgoing_message])

    params_outgoing_message.merge!({
      status: 'ready',
      message_type: 'followup',
      incoming_message_followup_id: @incoming_message.try(:id),
      info_request_id: @info_request.id
    })
    params_outgoing_message[:what_doing] = 'internal_review' if @internal_review

    parameters = ActionController::Parameters.new(params_outgoing_message)
    parameters.permit(:body,
                      :status,
                      :message_type,
                      :incoming_message_followup_id,
                      :info_request_id,
                      :what_doing)
  end

  def send_followup
    @outgoing_message.sendable?

    # OutgoingMailer.followup() depends on DB id of the
    # outgoing message, save just before sending.
    @outgoing_message.save!

    begin
      mail_message = OutgoingMailer.followup(
        @outgoing_message.info_request,
        @outgoing_message,
        @outgoing_message.incoming_message_followup
      ).deliver_now
    rescue *OutgoingMessage.expected_send_errors => e
      authority_name = @outgoing_message.info_request.public_body.name
      @outgoing_message.record_email_failure(e.message)
      if @outgoing_message.what_doing == 'internal_review'
        flash[:error] = _("Your internal review request has been saved but " \
                          "not yet sent to {{authority_name}} due to an error.",
                          authority_name: authority_name)
      else
        flash[:error] = _("Your follow up message has been saved but not yet " \
                          "sent to {{authority_name}} due to an error.",
                          authority_name: authority_name)
      end
    else
      @outgoing_message.record_email_delivery(
        mail_message.to_addrs.join(', '),
        mail_message.message_id
      )

      if @outgoing_message.what_doing == 'internal_review'
        flash[:notice] = _("Your internal review request has been sent on " \
                           "its way.")
      else
        flash[:notice] = _("Your follow up message has been sent on its way.")
      end

      @outgoing_message.info_request.reopen_to_new_responses
    ensure
      # Ensure DB is updated to isolate potential templating issues
      # from impacting delivery status information.
      @outgoing_message.save!
    end
  end

  def set_incoming_message
    @incoming_message = if params[:incoming_message_id].nil?
      nil
    else
      IncomingMessage.find(params[:incoming_message_id])
    end
  end

  def set_info_request
    if current_user && current_user.is_pro?
      @info_request =
        current_user.info_requests.find_by(id: params[:request_id].to_i)
    end
    @info_request ||= InfoRequest.not_embargoed.find(params[:request_id].to_i)
  end

  def set_last_request_data
    set_last_request(@info_request)
  end

  def set_outgoing_message
    @outgoing_message = OutgoingMessage.new(outgoing_message_params)
    @outgoing_message.set_signature_name(@user.name) if @user
  end

  def set_refusal_advice
    @refusal_advice = RefusalAdvice.default(
      @info_request,
      internal_review: @internal_review,
      user: current_user
    )
  end

  def set_params
    @is_owning_user = @info_request.is_owning_user?(authenticated_user)
    @gone_postal = params[:gone_postal]
    @gone_postal = false if !@is_owning_user
    set_postal_addresses if @gone_postal
    @collapse_quotes = !params[:unfold]
  end

  def set_postal_addresses
    @postal_email = @info_request.postal_email
    @postal_email_name = @info_request.postal_email_name
  end

  # An override of ApplicationController#set_in_pro_area to set the flag
  # whenever the info_request has an embargo, because we might not have a :pro
  # parameter to go on.
  def set_in_pro_area
    @in_pro_area = @info_request.embargo.present?
  end
end
