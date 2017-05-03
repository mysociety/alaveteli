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
        log.line(:redact => !@user.is_admin?)
      end
    end

    respond_to :html
  end

  protected

  def set_outgoing_message
    @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
  end

  def check_prominence
    unless can?(:read, @outgoing_message) && \
           can?(:read, @outgoing_message.info_request)
        return render_hidden('request/_hidden_correspondence',
                             :locals => { :message => @outgoing_message })
    end
  end
end
