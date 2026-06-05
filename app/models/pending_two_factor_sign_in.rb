# Wraps the session state for a sign-in that has passed the password check but
# still needs a second factor.
class PendingTwoFactorSignIn
  TTL = 5.minutes

  def initialize(session)
    @session = session
  end

  def start(user:, remember_me:, post_redirect:)
    @session[:pending_2fa_user_id] = user.id
    @session[:pending_2fa_started_at] = Time.zone.now.to_i
    @session[:pending_2fa_remember_me] = remember_me
    @session[:pending_2fa_post_redirect_token] = post_redirect.token
  end

  def user_id
    @session[:pending_2fa_user_id]
  end

  def remember_me
    @session[:pending_2fa_remember_me]
  end

  def user
    @user ||= User.find_by(id: user_id) if user_id
  end

  def post_redirect
    token = @session[:pending_2fa_post_redirect_token]
    @post_redirect ||= PostRedirect.find_by(token: token) if token
  end

  # started_at is stored as an epoch integer so it survives the JSON session
  # round-trip as a number rather than a string that needs coercing back.
  def expired?
    started_at = @session[:pending_2fa_started_at]
    started_at.nil? || started_at < TTL.ago.to_i
  end

  # A challenge is only live for a still-TOTP user inside the TTL window.
  def active?
    user&.totp? ? !expired? : false
  end

  def clear
    %i[pending_2fa_user_id
       pending_2fa_started_at
       pending_2fa_remember_me
       pending_2fa_post_redirect_token].each { |key| @session.delete(key) }
  end
end
