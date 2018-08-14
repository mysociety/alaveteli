# -*- encoding : utf-8 -*-
# app/controllers/admin_users_account_suspensions_controller.rb:
# Controller for suspending user accounts
#
# Copyright (c) 2018 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
class AdminUsersAccountSuspensionsController < AdminController
  before_filter :set_user
  before_filter :set_suspension_reason

  def create
    if suspend
      flash[:notice] = 'The user was suspended.'
    else
      flash[:error] = 'Something went wrong. The user could not be suspended.'
    end

    redirect_to admin_user_path(@user)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def suspend
    if params[:close_and_anonymise]
      @user.close_and_anonymise
    else
      @user.update(ban_text: @suspension_reason)
    end
  end

  def set_suspension_reason
    @suspension_reason =
      params[:suspension_reason] || _('Account suspended – Please contact us')
  end
end
