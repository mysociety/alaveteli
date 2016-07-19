# -*- encoding : utf-8 -*-
class OutgoingMessages::DeliveryStatusesController < ApplicationController
  before_filter :set_outgoing_message, :check_prominence

  def show
    @title = _('Delivery Status for Outgoing Message #{{id}}',
               :id => @outgoing_message.id)

    @delivery_status = @outgoing_message.delivery_status

    @show_mail_server_logs = @outgoing_message.is_owning_user?(@user)

    if @show_mail_server_logs
      @mail_server_logs = @outgoing_message.mail_server_logs.map do |log|
        log.line(:redact_idhash => !@user.super?)
      end
    end

    respond_to :html
  end

  protected

  def set_outgoing_message
    @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
  end

  def check_prominence
    unless @outgoing_message.user_can_view?(@user) &&
      @outgoing_message.info_request.user_can_view?(@user)
        return render_hidden('request/_hidden_correspondence',
                             :locals => { :message => @outgoing_message })
    end
  end
end
