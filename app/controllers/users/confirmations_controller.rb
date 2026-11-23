class Users::ConfirmationsController < UserController
  before_action :check_post_redirect_token

  def confirm
    user = post_redirect.user

    case post_redirect.circumstance
    when 'change_password'
      clear_session_credentials if current_user != user
      user.confirm!

    when 'normal', 'change_email'
      if current_user&.stay_logged_in_on_redirect?
        session[:admin_confirmation] = 1
      elsif current_user && current_user != user
        @reason_params = { user_name: user.name }
        render template: 'user/wrong_user'
        return
      else
        user.confirm!

        # A TOTP user must pass the 2FA challenge before the link grants a
        # session, or the confirmation link bypasses two factor. HOTP is not a
        # sign-in factor anywhere (see SessionsController), so gate on totp?.
        # Consume the link, stash the pending sign-in (with the circumstance the
        # challenge needs to resume), and hand off to the challenge.
        if user.totp?
          post_redirect.update!(
            email_token: PostRedirect.generate_random_token
          )
          PendingTwoFactorSignIn.new(session).start(
            user: user,
            remember_me: false,
            post_redirect: post_redirect,
            circumstance: post_redirect.circumstance
          )
          redirect_to signin_two_factor_path
          return
        end

        sign_in(user)
      end
    end

    post_redirect.update!(email_token: PostRedirect.generate_random_token)
    session[:user_circumstance] = post_redirect.circumstance
    do_post_redirect post_redirect, user
  end

  private

  def post_redirect
    @post_redirect ||= PostRedirect.find_by(email_token: params[:email_token])
  end

  def check_post_redirect_token
    return if post_redirect&.email_token_valid?

    render template: 'user/bad_token'
  end
end
