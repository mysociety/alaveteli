# app/controllers/admin_comment_controller.rb:
# Controller for editing comments from the admin interface.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminCommentController < AdminController

  before_action :set_comment, :only => [:edit, :update]

  def index
    @title = 'Listing comments'
    @query = params[:query]

    comments = if @query
      Comment.where(["lower(body) LIKE lower('%'||?||'%')", @query]).
        order('created_at DESC')
    else
      Comment.order('created_at DESC')
    end

    if cannot? :admin, AlaveteliPro::Embargo
      comments = comments.not_embargoed
    end

    @comments = comments.paginate :page => params[:page], :per_page => 100
  end

  def edit
    if cannot? :admin, @comment
      raise ActiveRecord::RecordNotFound
    end
  end

  def update
    if cannot? :admin, @comment
      raise ActiveRecord::RecordNotFound
    end

    if @comment.update(comment_params)
      update_type = if comment_hidden?
        'hide_comment'
      else
        'edit_comment'
      end

      @comment.info_request.log_event(
        update_type, {
          comment_id: @comment.id,
          editor: admin_current_user,
          old_body: @comment.body_previously_was,
          body: @comment.body,
          old_visible: @comment.visible_previously_was,
          visible: @comment.visible,
          old_attention_requested: @comment.attention_requested_previously_was,
          attention_requested: @comment.attention_requested
        }
      )

      flash[:notice] = 'Comment successfully updated.'
      redirect_to admin_request_url(@comment.info_request)
    else
      render :action => 'edit'
    end
  end

  private

  def comment_params
    if params[:comment]
      params.require(:comment).permit(:body, :visible, :attention_requested)
    else
      {}
    end
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_hidden?
    @comment.previous_changes[:visible] && !@comment.previous_changes[:body]
  end
end
