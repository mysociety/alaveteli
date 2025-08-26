##
# Adds unsubscribe helper methods to mailers
#
# Requires @user to be defined within the mailer action
#
module UnsubscribeHelper
  def unsubscribe_url
    signin_url(
      r: user_url(@user, anchor: 'email_subscriptions', only_path: true)
    )
  end

  def disable_email_alerts_url
    token = CGI.escape(User::EmailAlerts.token(@user))
    users_disable_email_alerts_url(token: token)
  end
end
