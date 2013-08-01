class AdminOutgoingMessageController < AdminController

    def edit
        @outgoing_message = OutgoingMessage.find(params[:id])
    end

    def destroy
        @outgoing_message = OutgoingMessage.find(params[:outgoing_message_id])
        @info_request = @outgoing_message.info_request
        outgoing_message_id = @outgoing_message.id

        @outgoing_message.fully_destroy
        @outgoing_message.info_request.log_event("destroy_outgoing",
            { :editor => admin_current_user(), :deleted_outgoing_message_id => outgoing_message_id })

        flash[:notice] = 'Outgoing message successfully destroyed.'
        redirect_to admin_request_show_url(@info_request)
    end

    def update
        @outgoing_message = OutgoingMessage.find(params[:id])

        old_body = @outgoing_message.body

        if @outgoing_message.update_attributes(params[:outgoing_message])
            @outgoing_message.info_request.log_event("edit_outgoing",
                { :outgoing_message_id => @outgoing_message.id, :editor => admin_current_user(),
                    :old_body => old_body, :body => @outgoing_message.body })
            flash[:notice] = 'Outgoing message successfully updated.'
            redirect_to admin_request_show_url(@outgoing_message.info_request)
        else
            render :action => 'edit'
        end
    end

end
