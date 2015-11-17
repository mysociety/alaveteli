# -*- encoding : utf-8 -*-
# app/controllers/one_time_passwords_controller.rb:
# View and update User one time passwords
#
# Copyright (c) 2015 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
class OneTimePasswordsController < ApplicationController
  before_filter :check_two_factor_config, :authenticate

  def show
  end

  def create
    @user.enable_otp

    if @user.save
      redirect_to one_time_password_path,
                  :notice => _('Two factor authentication enabled')
    else
      flash.now[:error] = _('Two factor authentication could not be enabled')
      render :show
    end
  end

  def update
    if @user.increment!(:otp_counter)
      redirect_to one_time_password_path,
                  :notice => _('Two factor one time passcode updated')
    else
      flash.now[:error] = _('Could not update your two factor one time passcode')
      render :show
    end
  end

  def destroy
    @user.disable_otp

    if @user.save
      redirect_to one_time_password_path,
                  :notice => _('Two factor authentication disabled')
    else
      flash.now[:error] = _('Two factor authentication could not be disabled')
      render :show
    end
  end

  private

  def check_two_factor_config
    unless AlaveteliConfiguration.enable_two_factor_auth
      raise ActiveRecord::RecordNotFound.new('Page not enabled')
    end
  end

  def authenticate
    post_redirect_params = {
      :web => _('To view your two factor authentication details'),
      :email => _('To view your two factor authentication details'),
      :email_subject => _('To view your two factor authentication details') }

    authenticated?(post_redirect_params)
  end
end
