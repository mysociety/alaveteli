# app/controllers/comments_controller.rb:
# Show annotations upon a request or other object.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

##
# Comments Controller handles adding annotations to requests.
#
class CommentsController < ApplicationController
  read_only

  before_action :find_info_request

  before_action :reject_unless_comments_allowed
  before_action :reject_if_user_banned
  before_action :set_in_pro_area

  before_action :build_comment
  before_action :build_track_thing

  before_action :reedit_comment, only: [:create]
  before_action :authenticate, only: [:create]
  before_action :check_for_spam_comment, only: [:create]

  before_action :validate_comment, only: [:preview, :create]

  def new
    # Default to subscribing to request when first viewing form
    params[:subscribe_to_request] = true unless params[:comment]
    @comment ||= @info_request.comments.build
  end

  def preview; end

  def create
    # This automatically saves dependent objects in the same transaction
    @comment = @info_request.add_comment(@comment)

    # Also subscribe to track for this request, so they get updates
    # (do this first, so definitely don't send alert)
    flash[:notice] = _("Thank you for making an annotation!")
    handle_subscription if params[:subscribe_to_request]

    # we don't use comment_url here, as then you don't see the flash at top of
    # page
    redirect_to request_url(@info_request)
  end

  private

  def build_comment
    return unless params[:comment]

    @comment = @info_request.comments.build(comment_params.merge(user: @user))
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def find_info_request
    raise "Unknown type #{ params[:type] }" unless params[:type] == 'request'

    @info_request = InfoRequest.find_by_url_title!(params[:url_title])
    return unless @info_request.embargo && cannot?(:read, @info_request)

    raise ActiveRecord::RecordNotFound
  end

  def build_track_thing
    @track_thing = TrackThing.create_track_for_request(@info_request)
  end

  # Are comments allowed on this request?
  def reject_unless_comments_allowed
    return if can? :create_comment, @info_request

    redirect_to request_url(@info_request),
                notice: _("Comments are not allowed on this request")
  end

  # Banned from adding comments?
  def reject_if_user_banned
    return if !authenticated? || authenticated_user.can_make_comments?

    if authenticated_user.banned?
      @details = authenticated_user.can_fail_html
      render template: 'user/banned'
    else
      render template: 'comments/rate_limited'
    end
  end

  # An override of ApplicationController#set_in_pro_area to set the flag
  # whenever the info_request has an embargo, because we might not have a :pro
  # parameter to go on.
  def set_in_pro_area
    @in_pro_area = @info_request.embargo.present?
  end

  def spam_comment?(comment_body, user)
    !user.confirmed_not_spam? &&
      AlaveteliSpamTermChecker.new.spam?(comment_body)
  end

  def block_spam_comments?
    AlaveteliConfiguration.block_spam_comments ||
      AlaveteliConfiguration.enable_anti_spam
  end

  # Sends an exception and blocks the comment depending on configuration.
  def check_for_spam_comment
    return unless spam_comment?(@comment.body, @user)

    if send_exception_notifications?
      e = Exception.new("Possible spam annotation from user #{ @user.id }")
      ExceptionNotifier.notify_exception(e, env: request.env)
    end

    return unless block_spam_comments?

    flash.now[:error] = _("Sorry, we're currently unable to add your " \
                          "annotation. Please try again later.")
    render action: 'new'
  end

  def reedit_comment
    return unless params[:reedit]

    render action: 'new'
  end

  def authenticate
    authenticated? || ask_to_login(
      web: _('To post your annotation'),
      email: _('Then your annotation to {{info_request_title}} will be ' \
               'posted.',
               info_request_title: @info_request.title),
      email_subject: _('Confirm your annotation to {{info_request_title}}',
                       info_request_title: @info_request.title)
    )
  end

  def handle_subscription
    @existing_track = TrackThing.find_existing(@user, @track_thing)

    if @user && @info_request.user == @user
      # don't subscribe to own request!
    elsif !@existing_track
      @track_thing.track_medium = 'email_daily'
      @track_thing.tracking_user_id = @user.id
      @track_thing.save!
      flash[:notice] += _(" You will also be emailed updates about the " \
                          "request.")
    else
      flash[:notice] += _(" You are already being emailed updates about the " \
                          "request.")
    end
  end

  def validate_comment
    return if params[:comment] && @comment.valid?

    flash.now[:error] = _("Please correct the errors below")
    render action: 'new'
  end
end
