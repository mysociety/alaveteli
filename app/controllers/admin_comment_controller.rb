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
    old_values = @comment.attribute_hash(allowed_params, "old")
    if @comment.update_attributes(comment_params)
      new_values = @comment.attribute_hash(allowed_params)
      meta_data = { :comment_id => @comment.id,
                    :editor => admin_current_user }
      event_info = [old_values, new_values, meta_data].inject(&:merge)
      @comment.info_request.log_event("edit_comment", event_info)
      flash[:notice] = 'Comment successfully updated.'
      redirect_to admin_request_url(@comment.info_request)
    else
      render :action => 'edit'
    end
  end

  private

  def allowed_params
    [:body, :visible]
  end

  def comment_params
    if params[:comment]
      params[:comment].slice(*allowed_params)
    else
      {}
    end
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

end
