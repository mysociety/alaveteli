# app/controllers/comment_controller.rb:
# Show annotations upon a request or other object.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: comment_controller.rb,v 1.3 2008-08-26 22:54:45 francis Exp $

class CommentController < ApplicationController
    
    def new
        if params[:type] == 'request'
            @info_request = InfoRequest.find_by_url_title(params[:url_title])
            @comment = Comment.new(params[:comment].merge({
                :comment_type => 'request', 
                :user => @user
            }))
        else
            raise "Unknown type " + params[:type]
        end

        # XXX this check should theoretically be a validation rule in the model
        @existing_comment = Comment.find_by_existing_comment(@info_request.id, params[:comment][:body])
        
        # See if values were valid or not
        if !@existing_comment.nil? || !@comment.valid? || params[:reedit]
            render :action => 'new'
            return
        end

        # Show preview page, if it is a preview
        if params[:preview].to_i == 1
            render :action => 'preview'
            return
        end

        if authenticated?(
                :web => "To post your annotation",
                :email => "Then your annotation to " + @info_request.title + " will be posted.",
                :email_subject => "Confirm your annotation to " + @info_request.title
            )
            @comment = @info_request.add_comment(params[:comment][:body], authenticated_user)
            # This automatically saves dependent objects in the same transaction
            @info_request.save!
            flash[:notice] = "Thank you for making an annotation!"
            redirect_to comment_url(@comment)
        else
            # do nothing - as "authenticated?" has done the redirect to signin page for us
        end
    end

end

