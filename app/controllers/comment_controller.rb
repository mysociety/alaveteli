# -*- encoding : utf-8 -*-
# app/controllers/comment_controller.rb:
# Show annotations upon a request or other object.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class CommentController < ApplicationController
  before_filter :check_read_only, :only => [ :new ]
  before_filter :find_info_request, :only => [ :new ]
  before_filter :create_track_thing, :only => [ :new ]
  before_filter :reject_unless_comments_allowed, :only => [ :new ]
  before_filter :reject_if_user_banned, :only => [ :new ]

  def new
    if params[:comment]
      @comment = Comment.new(params[:comment].merge({
                                                      :comment_type => 'request',
                                                      :user => @user
      }))
    end

    if params[:comment]
      # TODO: this check should theoretically be a validation rule in the model
      @existing_comment = Comment.find_existing(@info_request.id, params[:comment][:body])
    else
      # Default to subscribing to request when first viewing form
      params[:subscribe_to_request] = true
    end

    # See if values were valid or not
    if !params[:comment] || !@existing_comment.nil? || !@comment.valid? || params[:reedit]
      render :action => 'new'
      return
    end

    # Show preview page, if it is a preview
    if params[:preview].to_i == 1
      render :action => 'preview'
      return
    end

    if authenticated?(
        :web => _("To post your annotation"),
        :email => _("Then your annotation to {{info_request_title}} will be posted.",:info_request_title=>@info_request.title),
        :email_subject => _("Confirm your annotation to {{info_request_title}}",:info_request_title=>@info_request.title)
      )

      # Also subscribe to track for this request, so they get updates
      # (do this first, so definitely don't send alert)
      flash[:notice] = _("Thank you for making an annotation!")

      if params[:subscribe_to_request]
        @track_thing = TrackThing.create_track_for_request(@info_request)
        @existing_track = TrackThing.find_existing(@user, @track_thing)
        if @user && @info_request.user == @user
          # don't subscribe to own request!
        elsif !@existing_track
          @track_thing.track_medium = 'email_daily'
          @track_thing.tracking_user_id = @user.id
          @track_thing.save!
          flash[:notice] += _(" You will also be emailed updates about the request.")
        else
          flash[:notice] += _(" You are already being emailed updates about the request.")
        end
      end

      # This automatically saves dependent objects in the same transaction
      @comment = @info_request.add_comment(params[:comment][:body], authenticated_user)
      @info_request.save!

      # we don't use comment_url here, as then you don't see the flash at top of page
      redirect_to request_url(@info_request)
    else
      # do nothing - as "authenticated?" has done the redirect to signin page for us
    end
  end

  private

  def find_info_request
    if params[:type] == 'request'
      @info_request = InfoRequest.find_by_url_title!(params[:url_title])
    else
      raise "Unknown type #{ params[:type] }"
    end
  end

  def create_track_thing
    @track_thing = TrackThing.create_track_for_request(@info_request)
  end

  # Are comments disabled on this request?
  #
  # There is no “add comment” link when comments are disabled, so users should
  # not usually hit this unless they are explicitly attempting to avoid the comment block
  def reject_unless_comments_allowed
    unless @info_request.comments_allowed?
      redirect_to request_url(@info_request), :notice => "Comments are not allowed on this request"
    end
  end

  # Banned from adding comments?
  def reject_if_user_banned
    if authenticated_user && !authenticated_user.can_make_comments?
      @details = authenticated_user.can_fail_html
      render :template => 'user/banned'
    end
  end

end
