class AdminIncomingMessageController < AdminController

    def destroy_incoming
        @incoming_message = IncomingMessage.find(params[:incoming_message_id])
        @info_request = @incoming_message.info_request
        incoming_message_id = @incoming_message.id

        @incoming_message.fully_destroy
        @incoming_message.info_request.log_event("destroy_incoming",
            { :editor => admin_current_user(), :deleted_incoming_message_id => incoming_message_id })
        # expire cached files
        expire_for_request(@info_request)
        flash[:notice] = 'Incoming message successfully destroyed.'
        redirect_to admin_request_show_url(@info_request)
    end

    def redeliver_incoming
        incoming_message = IncomingMessage.find(params[:redeliver_incoming_message_id])
        message_ids = params[:url_title].split(",").each {|x| x.strip}
        previous_request = incoming_message.info_request
        destination_request = nil
        ActiveRecord::Base.transaction do
            for m in message_ids
                if m.match(/^[0-9]+$/)
                    destination_request = InfoRequest.find_by_id(m.to_i)
                else
                    destination_request = InfoRequest.find_by_url_title!(m)
                end
                if destination_request.nil?
                    flash[:error] = "Failed to find destination request '" + m + "'"
                    return redirect_to admin_request_show_url(previous_request)
                end

                raw_email_data = incoming_message.raw_email.data
                mail = MailHandler.mail_from_raw_email(raw_email_data)
                destination_request.receive(mail, raw_email_data, true)

                incoming_message_id = incoming_message.id
                incoming_message.info_request.log_event("redeliver_incoming", {
                                                            :editor => admin_current_user(),
                                                            :destination_request => destination_request.id,
                                                            :deleted_incoming_message_id => incoming_message_id
                                                        })

                flash[:notice] = "Message has been moved to request(s). Showing the last one:"
            end
            # expire cached files
            expire_for_request(previous_request)
            incoming_message.fully_destroy
        end
        redirect_to admin_request_show_url(destination_request)
    end

end
