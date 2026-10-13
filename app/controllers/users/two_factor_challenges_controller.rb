# 2FA gate for sign-in. The user has passed the password check but is not signed
# in yet. The pending sign-in lives in the session (see PendingTwoFactorSignIn).
# A correct authenticator code completes the sign-in and sends the user on to
# their original destination.
class Users::TwoFactorChallengesController < UserController
  include OtpRateLimit

  before_action :load_pending_sign_in

  limit_otp_attempts only: :create, by: -> { @pending.user_id }, template: :new

  def new
  end

  def create
    if @pending.user.authenticate_otp(params[:otp_code])
      flash_backup_code_warning(@pending.user)
      complete_two_factor_sign_in
    else
      flash.now[:error] = _('Invalid one time password')
      render :new
    end
  end

  private

  def load_pending_sign_in
    @pending = PendingTwoFactorSignIn.new(session)
    return if @pending.active?

    @pending.clear
    redirect_to signin_path
  end

  def complete_two_factor_sign_in
    complete_sign_in(
      @pending.user,
      post_redirect: @pending.post_redirect,
      remember_me: @pending.remember_me,
      circumstance: @pending.circumstance
    )
  end

  def flash_backup_code_warning(user)
    return unless user.used_backup_code?

    flash[:notice] = {
      partial: 'one_time_passwords/backup_code_used',
      locals: { remaining: user.otp_backup_codes.size }
    }
  end
end
