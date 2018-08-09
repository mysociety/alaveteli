# -*- encoding : utf-8 -*-
class UserProfile::AboutMeController < ApplicationController
  before_filter :set_title
  before_filter :check_user_logged_in

  def edit ; end

  def update
    if @user.suspended?
      flash[:error] = _('Suspended users cannot edit their profile')
      redirect_to edit_profile_about_me_path
      return
    end

    # TODO: Use strong params to require :user key
    return redirect_to user_url(@user) unless params[:user]
    @user.about_me = params[:user][:about_me]

    unless @user.confirmed_not_spam?
      if UserSpamScorer.new.spam?(@user)
        flash[:error] = _("You can't update your profile text at this time.")
        redirect_to user_url(@user)
        return
      end
    end

    if spam_about_me_text?(@user.about_me, @user)
      handle_spam_about_me_text(@user) && return
    end

    if @user.save
      if @user.profile_photo
        flash[:notice] = _("You have now changed the text about you on your profile.")
        redirect_to user_url(@user)
      else
        flash[:notice] = { :partial => "update_profile_text.html.erb" }
        redirect_to set_profile_photo_url
      end
    else
      render :edit
    end
  end

  private

  def check_user_logged_in
    if authenticated_user.nil?
      flash[:error] = _("You need to be logged in to change the text about you on your profile.")
      redirect_to frontpage_url
      return
    end
  end

  def set_title
    @title = _('Change the text about you on your profile at {{site_name}}',
               :site_name => site_name)
  end

  def spam_about_me_text?(text, user)
    !user.confirmed_not_spam? &&
      AlaveteliSpamTermChecker.new.spam?(text)
  end

  def block_spam_about_me_text?
    AlaveteliConfiguration.block_spam_about_me_text ||
      AlaveteliConfiguration.enable_anti_spam
  end

  def handle_spam_about_me_text(user)
    if send_exception_notifications?
      e = Exception.new("Spam about me text from user #{ user.id }")
      ExceptionNotifier.notify_exception(e, :env => request.env)
    end

    if block_spam_about_me_text?
      flash[:error] = _("You can't update your profile text at this time.")
      redirect_to user_url(user)
      true
    end
  end
end
