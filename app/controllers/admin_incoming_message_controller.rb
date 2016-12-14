# -*- encoding : utf-8 -*-
class AdminIncomingMessageController < AdminController

  before_filter :set_incoming_message, :only => [:edit, :update, :destroy, :redeliver]

  def edit
  end

  def update
    old_prominence = @incoming_message.prominence
    old_prominence_reason = @incoming_message.prominence_reason
    if @incoming_message.update_attributes(incoming_message_params)
      @incoming_message.info_request.log_event('edit_incoming',
                                               :incoming_message_id => @incoming_message.id,
                                               :editor => admin_current_user,
                                               :old_prominence => old_prominence,
                                               :prominence => @incoming_message.prominence,
                                               :old_prominence_reason => old_prominence_reason,
                                               :prominence_reason => @incoming_message.prominence_reason)
      @incoming_message.info_request.expire
      flash[:notice] = 'Incoming message successfully updated.'
      redirect_to admin_request_url(@incoming_message.info_request)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @incoming_message.destroy
    @incoming_message.info_request.log_event("destroy_incoming",
                                             { :editor => admin_current_user,
                                              :deleted_incoming_message_id => @incoming_message.id })
    # expire cached files
    @incoming_message.info_request.expire(:preserve_database_cache => true)
    flash[:notice] = 'Incoming message successfully destroyed.'
    redirect_to admin_request_url(@incoming_message.info_request)
  end

  def bulk_destroy
    if params[:commit] == "No"
      redirect_to(admin_request_url(params[:request_id]))
    end

    @incoming_messages = IncomingMessage.where(:id => params[:ids].split(","))
    if params[:commit] == "Yes"
      errors = []
      info_request = InfoRequest.find(params[:request_id])
      @incoming_messages.each do |message|
        begin
          message.destroy
          info_request.log_event("destroy_incoming",
                                 { :editor => admin_current_user,
                                   :deleted_incoming_message_id => message.id })
        rescue
          errors << message.id
        end
      end
      info_request.expire(:preserve_database_cache => true)
      if errors.empty?
        flash[:notice] = "Incoming messages successfully destroyed."
      else
        flash[:error] = <<-EOF.strip_heredoc
          Only some incoming messages were destroyed.
          Incoming Messages #{ errors.join(', ') } could not be destroyed.
          Try destroying them individually.
        EOF
      end
      redirect_to(admin_request_url(params[:request_id]))
    end
  end

  def redeliver

    message_ids = params[:url_title].split(",").each {|x| x.strip}
    previous_request = @incoming_message.info_request
    destination_request = nil

    if message_ids.empty?
      flash[:error] = "You must supply at least one request to redeliver the message to."
      return redirect_to admin_request_url(previous_request)
    end

    ActiveRecord::Base.transaction do
      for m in message_ids
        if m.match(/^[0-9]+$/)
          destination_request = InfoRequest.find_by_id(m.to_i)
        else
          destination_request = InfoRequest.find_by_url_title!(m)
        end
        if destination_request.nil?
          flash[:error] = "Failed to find destination request '" + m + "'"
          return redirect_to admin_request_url(previous_request)
        end

        raw_email_data = @incoming_message.raw_email.data
        mail = MailHandler.mail_from_raw_email(raw_email_data)
        destination_request.receive(mail, raw_email_data, true)

        @incoming_message.info_request.log_event("redeliver_incoming", {
                                                  :editor => admin_current_user,
                                                  :destination_request => destination_request.id,
                                                  :deleted_incoming_message_id => @incoming_message.id
        })

        flash[:notice] = "Message has been moved to request(s). Showing the last one:"
      end
      # expire cached files
      previous_request.expire
      @incoming_message.destroy
    end
    redirect_to admin_request_url(destination_request)
  end

  private

  def incoming_message_params
    if params[:incoming_message]
      params.require(:incoming_message).permit(:prominence, :prominence_reason)
    else
      {}
    end
  end

  def set_incoming_message
    @incoming_message = IncomingMessage.find(params[:id])
  end

end
