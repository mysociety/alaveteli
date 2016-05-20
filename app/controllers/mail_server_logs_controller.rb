# -*- encoding : utf-8 -*-
class MailServerLogsController < ApplicationController
  before_filter :set_subject, :check_prominence

  def index
    @title =
      case @subject.class.to_s
      when 'OutgoingMessage'
        _('Mail Server Logs for Outgoing Message #{{id}}', :id => @subject.id)
      end

    @mail_server_logs = @subject.mail_server_logs.map do |log|
      log.line(:redact_idhash => !@user.super?)
    end

    respond_to do |format|
      format.html
      format.text { render :text => @mail_server_logs.join }
    end
  end

  protected

  def set_subject
    @subject =
      if params[:outgoing_message_id]
        OutgoingMessage.find(params[:outgoing_message_id])
      end
  end

  def check_prominence
    unless @subject.is_owning_user?(@user)
      return render_hidden('request/_hidden_correspondence',
                           :locals => { :message => @subject })
    end
  end
end
