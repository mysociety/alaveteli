# -*- encoding : utf-8 -*-
# app/controllers/admin_comment_controller.rb:
# Controller for editing comments from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminCommentController < AdminController
    before_filter :set_comment, :only => [:edit, :update]

    def edit
    end

    def update
        old_body = @comment.body
        old_visible = @comment.visible

        if @comment.update_attributes(params[:comment])
            @comment.info_request.log_event("edit_comment",
                { :comment_id => @comment.id,
                  :editor => admin_current_user(),
                  :old_body => old_body,
                  :body => @comment.body,
                  :old_visible => old_visible,
                  :visible => @comment.visible,
                })
            redirect_to admin_request_url(@comment.info_request), :notice => 'Comment successfully updated.'
        else
            render :edit
        end
    end

    private

    def set_comment
        @comment = Comment.find(params[:id])
    end

end
