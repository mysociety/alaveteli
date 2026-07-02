# app/controllers/one_time_passwords_controller.rb:
# View and update User one time passwords
#
# Copyright (c) 2015 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
class OneTimePasswordsController < ApplicationController
  include OtpRateLimit

  before_action :check_two_factor_config, :authenticate
  before_action :prevent_reenrolment, only: [:new, :create]
  before_action :require_hotp, only: :update
  before_action :require_pending_otp_secret, only: :create

  limit_otp_attempts only: :destroy, by: -> { @user.id },
                     if: -> { @user.totp? && !params[:otp_code].nil? },
                     template: :destroy_confirmation

  def new
    session[:pending_otp_secret_key] ||= ROTP::Base32.random
    @enrolment = OtpEnrolment.new(
      user: @user, secret: session[:pending_otp_secret_key]
    )
  end

  def show
  end

  def create
    @enrolment = OtpEnrolment.new(
      user: @user,
      secret: session[:pending_otp_secret_key],
      otp_code: enrolment_params[:otp_code].to_s
    )

    if @enrolment.save
      session.delete(:pending_otp_secret_key)
      if @user.otp_counter_previously_was.present?
        flash[:just_upgraded_from_hotp] = true
      end
      flash[:backup_codes] = @enrolment.backup_codes
      redirect_to one_time_password_path,
                  notice: _('Two factor authentication enabled')
    else
      render :new
    end
  end

  def update
    if @user.increment!(:otp_counter)
      redirect_to one_time_password_path,
                  notice: _('Two factor one time passcode updated')
    else
      flash.now[:error] = _('Could not update your two factor one time passcode')
      render :show
    end
  end

  def destroy
    if @user.totp?
      return render :destroy_confirmation if params[:otp_code].nil?

      unless @user.authenticate_otp(params[:otp_code])
        flash.now[:error] = _('Invalid one time password')
        return render :destroy_confirmation
      end
    end

    @user.disable_otp

    if @user.save
      redirect_to one_time_password_path,
                  notice: _('Two factor authentication disabled')
    else
      flash.now[:error] = _('Two factor authentication could not be disabled')
      render :show
    end
  end

  private

  def enrolment_params
    params.fetch(:otp_enrolment, {}).permit(:otp_code)
  end

  # Block enrolment for users who already have an authenticator app. HOTP users
  # are allowed through so they can upgrade to an authenticator app.
  def prevent_reenrolment
    return unless @user.totp?

    flash[:error] =
      _('Two factor authentication is already set up. To use a different ' \
        'authenticator app, disable two factor authentication first, then ' \
        'set it up again.')
    redirect_to one_time_password_path
  end

  # Prevent TOTP users from being downgraded to HOTP by restricting to HOTP
  # users only.
  def require_hotp
    return if @user.hotp?

    flash[:error] =
      _('Your account does not have a two factor one time passcode to update')
    redirect_to one_time_password_path
  end

  def require_pending_otp_secret
    return if session[:pending_otp_secret_key].present?

    flash[:notice] = _('Your two factor authentication setup expired. ' \
                       'Please scan the new QR code below to start again.')
    redirect_to new_one_time_password_path
  end

  def check_two_factor_config
    unless AlaveteliConfiguration.enable_two_factor_auth
      raise ActiveRecord::RecordNotFound, 'Page not enabled'
    end
  end

  def authenticate
    authenticated? || ask_to_login(
      web: _('To view your two factor authentication details'),
      email: _('To view your two factor authentication details'),
      email_subject: _('To view your two factor authentication details')
    )
  end
end
