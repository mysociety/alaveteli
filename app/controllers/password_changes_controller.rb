# app/controllers/password_changes_controller.rb:
# Change a User's password
#
# Copyright (c) 2015 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class PasswordChangesController < ApplicationController
  include OtpRateLimit

  before_action :set_pretoken
  before_action :set_pretoken_hash
  before_action :set_user_from_token, only: [:edit, :update]
  before_action :require_change_user, only: [:edit, :update]
  before_action :set_otp_enabled, only: [:edit, :update]

  limit_otp_attempts only: :update,
                     if: -> { @otp_enabled },
                     by: -> { @password_change_user.id },
                     template: :edit

  def new
    @email_field_options =
      @user ? { disabled: true, value: @user.email } : {}
  end

  def create
    unless @user || params[:password_change_user]
      @email_field_options = {}
      render :new
      return
    end

    email = @user ? @user.email : params[:password_change_user][:email]

    unless MySociety::Validate.is_valid_email(email)
      flash[:error] = _("That doesn't look like a valid email address. " \
                        "Please check you have typed it correctly.")
      @email_field_options =
        @user ? { disabled: true, value: email } : {}
      render :new
      return
    end

    @password_change_user = User.find_user_by_email(email)

    if @password_change_user
      post_redirect_attrs =
        { post_params: {},
          reason_params:             { web: '',
              email: _('Then you can change your password on {{site_name}}',
                          site_name: site_name),
              email_subject: _('Change your password on {{site_name}}',
                                  site_name: site_name) },
          circumstance: 'change_password',
          user: @password_change_user }
      post_redirect = PostRedirect.new(post_redirect_attrs)
      post_redirect.uri = edit_password_change_url(post_redirect.token,
                                                   @pretoken_hash)
      post_redirect.save!

      url = confirm_url(email_token: post_redirect.email_token)
      UserMailer.
        confirm_login(@password_change_user, post_redirect.reason_params, url).
          deliver_now
    end

    render :check_email
  end

  def edit
  end

  def update
    @pretoken_redirect = PostRedirect.find_by(token: @pretoken) if @pretoken

    @password_change_user.password = params[:password_change_user][:password]
    @password_change_user.password_confirmation =
      params[:password_change_user][:password_confirmation]

    if @otp_enabled
      @password_change_user.entered_otp_code =
        params[:password_change_user][:otp_code]
      @password_change_user.require_otp = true
    end

    if @password_change_user.save
      sign_in(@password_change_user)

      if @otp_enabled && @password_change_user.hotp?
        msg = _("Your password has been changed. " \
                "You also have a new one time passcode which you'll " \
                "need next time you want to change your password")
        redirect_to one_time_password_path, notice: msg
      elsif @pretoken_redirect
        redirect_to SafeRedirect.new(@pretoken_redirect.uri).path,
                    notice: password_changed_notice(@password_change_user)
      else
        redirect_to show_user_profile_path(@password_change_user.url_name),
                    notice: password_changed_notice(@password_change_user)
      end
    else
      render :edit
    end
  end

  protected

  def password_changed_notice(user)
    changed = _('Your password has been changed.')
    return changed unless user.used_backup_code?

    { partial: 'one_time_passwords/backup_code_used',
      locals: { lead: changed, remaining: user.otp_backup_codes.size } }
  end

  def set_pretoken
    @pretoken = params.fetch(:pretoken, '').blank? ? nil : params[:pretoken]
  end

  def set_pretoken_hash
    @pretoken_hash = @pretoken ? { pretoken: @pretoken } : {}
  end

  def set_user_from_token
    @password_change_user ||=
      if params[:id]
        post_redirect = PostRedirect.find_by(
          token: params[:id],
          circumstance: 'change_password'
        )
        post_redirect.user if post_redirect
      end
  end

  # Edit and update need a user resolved from the token to change a password
  # against. Bail out early when there isn't one, before the OTP rate limit and
  # password logic run, so both can assume a user is present.
  def require_change_user
    return if @password_change_user

    redirect_to new_password_change_path(@pretoken_hash)
  end

  def set_otp_enabled
    @otp_enabled = otp_enabled?(@password_change_user)
  end

  def otp_enabled?(user)
    AlaveteliConfiguration.enable_two_factor_auth && user.otp_enabled?
  end
end
