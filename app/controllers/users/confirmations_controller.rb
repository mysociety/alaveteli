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
      else
        user.confirm!
        sign_in(user)
      end
    end

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
