# -*- encoding : utf-8 -*-
class OneTimePasswordsController < ApplicationController
  before_filter :check_2factor_config, :authenticate

  def show

  end

  def create
    @user.enable_otp

    if @user.save
      redirect_to one_time_password_path,
                  :notice => _('2factor authentication enabled')
    else
      render :show
    end
  end

  def destroy
    @user.disable_otp

    if @user.save
      redirect_to one_time_password_path,
                  :notice => _('2factor authentication disabled')
    else
      render :show
    end
  end

  private

  def check_2factor_config
    unless AlaveteliConfiguration.enable_2factor_auth
      raise ActiveRecord::RecordNotFound.new('Page not enabled')
    end
  end

  def authenticate
    post_redirect_params = {
      :web => _('Sign in to view your 2factor authentication details'),
      :email => _('Sign in to view your 2factor authentication details'),
      :email_subject => _('Sign in to view your 2factor authentication details') }

    authenticated?(post_redirect_params)
  end

end
