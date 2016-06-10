# -*- encoding : utf-8 -*-
class OutgoingMessages::DeliveryStatusesController < ApplicationController
  before_filter :set_outgoing_message, :check_prominence

  def show
    @title = _('Delivery Status for Outgoing Message #{{id}}',
               :id => @outgoing_message.id)

    @mail_server_logs = @outgoing_message.mail_server_logs.map do |log|
      log.line(:redact_idhash => !@user.super?)
    end

    @delivery_status = @outgoing_message.delivery_status

    respond_to :html
  end

  protected

  def set_outgoing_message
    @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
  end

  def check_prominence
    unless @outgoing_message.is_owning_user?(@user)
      return render_hidden('request/_hidden_correspondence',
                           :locals => { :message => @outgoing_message })
    end
  end
end
