# -*- encoding : utf-8 -*-
# app/controllers/admin_users_sessions_controller.rb:
# Controller for logging in as another user
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AdminUsersSessionsController < AdminController
  def create
    # Don't use @user as that is any logged in user
    @admin_user = User.find(params[:id])

    if cannot? :login_as, @admin_user
      flash[:error] =
        "You don't have permission to log in as #{ @admin_user.name }"
      return redirect_to admin_user_path(@admin_user)
    end

    @admin_user.confirm!

    session[:user_id] = @admin_user.id
    session[:user_circumstance] = 'login_as'

    redirect_to user_path(@admin_user)
  end
end
