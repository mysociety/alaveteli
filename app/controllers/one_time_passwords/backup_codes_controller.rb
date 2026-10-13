# View and regenerate two factor backup codes
class OneTimePasswords::BackupCodesController < ApplicationController
  include OtpRateLimit

  before_action :check_two_factor_config, :authenticate, :require_totp

  limit_otp_attempts only: :create, by: -> { @user.id }, template: :show

  def show
  end

  def create
    unless @user.authenticate_otp(params[:otp_code].to_s)
      flash.now[:error] = _('Invalid one time password')
      return render :show
    end

    codes = @user.otp_regenerate_backup_codes

    if @user.save
      flash[:backup_codes] = codes
      redirect_to one_time_password_backup_codes_path,
                  notice: _('New backup codes generated')
    else
      flash.now[:error] = _('Backup codes could not be regenerated')
      render :show
    end
  end

  private

  def check_two_factor_config
    return if AlaveteliConfiguration.enable_two_factor_auth

    raise ActiveRecord::RecordNotFound, 'Page not enabled'
  end

  def authenticate
    authenticated? || ask_to_login(
      web: _('To manage your two factor backup codes'),
      email: _('To manage your two factor backup codes'),
      email_subject: _('To manage your two factor backup codes')
    )
  end

  # Backup codes only exist for TOTP users. HOTP and no-2FA users manage
  # their setup from the two factor settings page.
  def require_totp
    return if @user&.totp?

    redirect_to one_time_password_path
  end
end
