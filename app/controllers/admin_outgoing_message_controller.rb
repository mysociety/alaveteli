# -*- encoding : utf-8 -*-
class AdminOutgoingMessageController < AdminController

  before_filter :set_outgoing_message, :only => [:edit, :destroy, :update, :resend]

  def edit
  end

  def destroy
    @outgoing_message.fully_destroy
    @outgoing_message.info_request.log_event("destroy_outgoing",
                                             { :editor => admin_current_user,
                                               :deleted_outgoing_message_id => @outgoing_message.id })

    flash[:notice] = 'Outgoing message successfully destroyed.'
    redirect_to admin_request_url(@outgoing_message.info_request)
  end

  def update
    old_body = @outgoing_message.body
    old_prominence = @outgoing_message.prominence
    old_prominence_reason = @outgoing_message.prominence_reason
    if @outgoing_message.update_attributes(outgoing_message_params)
      @outgoing_message.info_request.log_event("edit_outgoing",
                                               { :outgoing_message_id => @outgoing_message.id,
                                                 :editor => admin_current_user,
                                                 :old_body => old_body,
                                                 :body => @outgoing_message.body,
                                                 :old_prominence => old_prominence,
                                                 :old_prominence_reason => old_prominence_reason,
                                                 :prominence => @outgoing_message.prominence,
                                                 :prominence_reason => @outgoing_message.prominence_reason })
      flash[:notice] = 'Outgoing message successfully updated.'
      expire_for_request(@outgoing_message.info_request)
      redirect_to admin_request_url(@outgoing_message.info_request)
    else
      render :action => 'edit'
    end
  end

  def resend
    @outgoing_message.prepare_message_for_resend

    mail_message = case @outgoing_message.message_type
    when 'initial_request'
      OutgoingMailer.initial_request(
        @outgoing_message.info_request,
        @outgoing_message
      ).deliver
    when 'followup'
      OutgoingMailer.followup(
        @outgoing_message.info_request,
        @outgoing_message,
        @outgoing_message.incoming_message_followup
      ).deliver
    else
      raise "Message id #{id} has type '#{message_type}' which cannot be resent"
    end

    @outgoing_message.record_email_delivery(
      mail_message.to_addrs.join(', '),
      mail_message.message_id,
      'resent'
    )

    flash[:notice] = "Outgoing message resent"
    redirect_to admin_request_url(@outgoing_message.info_request)
  end

  private

  def outgoing_message_params
    if params[:outgoing_message]
      params[:outgoing_message].slice(:prominence, :prominence_reason, :body)
    else
      {}
    end
  end

  def set_outgoing_message
    @outgoing_message = OutgoingMessage.find(params[:id])
  end

end
