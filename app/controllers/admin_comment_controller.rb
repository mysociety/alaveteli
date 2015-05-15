# -*- encoding : utf-8 -*-
# app/controllers/admin_comment_controller.rb:
# Controller for editing comments from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminCommentController < AdminController

    def edit
        @comment = Comment.find(params[:id])
    end

    def update
        @comment = Comment.find(params[:id])

        old_body = @comment.body
        old_visible = @comment.visible
        @comment.visible = params[:comment][:visible] == "true" ? true : false

        if @comment.update_attributes(params[:comment])
            @comment.info_request.log_event("edit_comment",
                { :comment_id => @comment.id,
                  :editor => admin_current_user(),
                  :old_body => old_body,
                  :body => @comment.body,
                  :old_visible => old_visible,
                  :visible => @comment.visible,
                })
            flash[:notice] = 'Comment successfully updated.'
            redirect_to admin_request_url(@comment.info_request)
        else
            render :action => 'edit'
        end
    end

end
