# app/controllers/admin_users_sessions_controller.rb:
# Controller for logging in as another user
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminUsersSessionsController < AdminController
  def create
    # Don't use @user as that is any logged in user
    @user_to_login_as = User.find(params[:id])

    if cannot? :login_as, @user_to_login_as
      flash[:error] =
        "You don't have permission to log in as #{ @user_to_login_as.name }"
      return redirect_to admin_user_path(@user_to_login_as)
    end

    @user_to_login_as.confirm!

    session[:admin_id] = current_user.id
    session[:user_id] = @user_to_login_as.id
    session[:user_login_token] = @user_to_login_as.login_token
    session[:user_circumstance] = 'login_as'

    redirect_to user_path(@user_to_login_as)
  end
end
