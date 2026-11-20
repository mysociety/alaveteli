class AdminIncomingMessageController < AdminController
  before_action :set_incoming_message, only: [:edit, :show, :update, :destroy]
  before_action :set_info_request, :check_info_request

  def show
  end

  def edit
  end

  def update
    if params[:save_tags]
      old_tag_string = @incoming_message.tag_string
      evt = {
        editor: admin_current_user,
        old_tag_string: old_tag_string,
        tag_string: incoming_message_params['tag_string']
      }

      if @incoming_message.update_and_log_event(
        event: evt, **incoming_message_params
      )
        @incoming_message.info_request.expire
        flash[:notice] = 'Incoming message successfully updated.'
      end
    elsif params[:save_incoming_message]
      unless @incoming_message.raw_email.erasable?
        flash[:error] = 'Some attachments have not been masked. Cannot edit this  message.'
        redirect_to admin_incoming_message_path(@incoming_message)
        return
      end

      reason = params[:edit_reason]
      # the event is almost empty on purpose: this is likely only used to
      # get rid of PII, so we don't want to store a copy in the event log.
      evt = {
        editor: admin_current_user,
        reason: reason
      }
      ActiveRecord::Base.transaction do
        @incoming_message.raw_email.erase!(**evt)

        @incoming_message.update_and_log_event!(
          event: evt, **incoming_message_params
        )

        @incoming_message.info_request.expire
      end
      flash[:notice] = 'Incoming message successfully updated.'
    end
    redirect_to admin_incoming_message_url(@incoming_message)
  end

  def destroy
    @incoming_message.destroy
    @incoming_message.info_request.log_event(
      'destroy_incoming',
      editor: admin_current_user,
      deleted_incoming_message_id: @incoming_message.id,
      storage_keys: @incoming_message.storage_keys
    )
    # expire cached files
    @incoming_message.info_request.expire(preserve_database_cache: true)
    flash[:notice] = 'Incoming message successfully destroyed.'
    redirect_to admin_request_url(@incoming_message.info_request)
  end

  def bulk_destroy
    if params[:commit] == "No"
      redirect_to(admin_request_url(params[:request_id]))
    end

    @incoming_messages = IncomingMessage.
                           where(id: params[:ids].split(",").flatten)
    if params[:commit] == "Yes"
      errors = []
      info_request = InfoRequest.find(params[:request_id])
      @incoming_messages.each do |message|
        message.destroy
        info_request.log_event(
          'destroy_incoming',
          editor: admin_current_user,
          deleted_incoming_message_id: message.id,
          storage_keys: message.storage_keys
        )
      rescue
        errors << message.id
      end
      info_request.expire(preserve_database_cache: true)
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

  private

  def incoming_message_params
    if params[:incoming_message]
      if params[:save_tags]
        params.expect(incoming_message: :tag_string)
      else
        params.expect(
          incoming_message: [
            :from_name,
            :from_email,
            :from_email_domain,
            :subject,
            :edit_reason
          ]
        )
      end
    else
      {}
    end
  end

  def set_incoming_message
    @incoming_message = IncomingMessage.find(params[:id])
  end

  def set_info_request
    @info_request = @incoming_message&.info_request || InfoRequest.find(
      params[:request_id]
    )
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end
