# -*- encoding : utf-8 -*-
class Users::SessionsController < UserController

  before_filter :work_out_post_redirect, :only => [ :new, :create ]
  before_filter :set_request_from_foreign_country, :only => [ :new, :create ]

  def new
    render :template => 'user/sign'
  end

  def create
    if @post_redirect.present?
      @user_signin =
        User.authenticate_from_form(user_signin_params,
                                    @post_redirect.reason_params[:user_name])
    end
    if @post_redirect.nil? || @user_signin.errors.size > 0
      # Failed to authenticate
      render :template => 'user/sign'
    else
      # Successful login
      if @user_signin.email_confirmed
        session[:user_id] = @user_signin.id
        session[:ttl] = nil
        session[:user_circumstance] = nil
        session[:remember_me] = params[:remember_me] ? true : false

        if is_modal_dialog
          render :template => 'users/sessions/show'
        else
          do_post_redirect @post_redirect, @user_signin, :signin
        end
      else
        send_confirmation_mail @user_signin
      end
    end
  end

  def destroy
    clear_session_credentials
    if params[:r]
      redirect_to URI.parse(params[:r]).path
    else
      redirect_to frontpage_path
    end
  end

  private

  def user_signin_params
    params.require(:user_signin).permit(:email, :password)
  end

end
