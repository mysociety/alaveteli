class UserProfile::NotificationPreferencesController < ApplicationController
  before_action :set_title
  before_action :check_user_logged_in

  def edit; end

  def update
    if @user.suspended?
      redirect_to edit_profile_notification_preferences_path,
                  error: _('Suspended users cannot edit their profile')
      return
    end

    unless params[:user]
      redirect_to edit_profile_notification_preferences_path
      return
    end

    @user.send_daily_summary = ActiveModel::Type::Boolean.new.cast(user_params[:send_daily_summary])
    @user.send_immediate_request_alerts = ActiveModel::Type::Boolean.new.cast(user_params[:send_immediate_request_alerts])

    if @user.save
      flash[:notice] = _("Your notification preferences have been updated.")
      redirect_to edit_profile_notification_preferences_path
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:send_daily_summary, :send_immediate_request_alerts)
  end

  def check_user_logged_in
    return if authenticated?

    msg = _('You need to be logged in to change your notification preferences.')
    redirect_to frontpage_url, error: msg
  end

  def set_title
    @title = _('Change your notification preferences at {{site_name}}',
               site_name: site_name)
  end
end
