# Handles the process of a user requesting to close their account.
class Users::CloseAccountController < ApplicationController
  before_action :authenticate_user!

  def new
    # Display a form that explains the process to the users
  end

  def create
    # If they haven't checked the "confirm" checkbox, redirect back to the form
    if params[:confirm] == "0"
      return redirect_to users_close_account_path,
        error: "You must confirm that you want to close your account"
    end

    # Otherwise, create a record of the user's request to close their account
    current_user.create_account_closure_request!

    # Send the user an acknowledgement email
    UserMailer.account_closure_requested(current_user).deliver_now

    # TODO: Should the user be logged out here?

    redirect_to root_path,
      notice: "Your account closure request has been received. " \
      "We will be in touch."
  end

  private

  def authenticate_user!
    return if authenticated?

    ask_to_login(
      web: _('To close your account on {{site_name}}', site_name: site_name),
      email: _(
        'Then you can close your account on {{site_name}}',
        site_name: site_name
      ),
      email_subject: _(
        'Close your account on {{site_name}}',
        site_name: site_name
      )
    )
  end
end
