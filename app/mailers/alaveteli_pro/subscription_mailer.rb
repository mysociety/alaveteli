# Alerts relating to subscriptions.
class AlaveteliPro::SubscriptionMailer < ApplicationMailer
  def payment_failed(user)
    auto_generated_headers(user)

    @user_name = user.name
    @pro_site_name = pro_site_name.html_safe
    @subscriptions_url = subscriptions_url
    mail_user(
      user,
      subject: -> { _(
        'Action Required: Payment failed on {{pro_site_name}}',
        pro_site_name: pro_site_name
      ) }
    )
  end

  private

  def auto_generated_headers(user)
    headers(
      'Return-Path' => blackhole_email,
      'Reply-To' => contact_for_user(user),
      'Auto-Submitted' => 'auto-generated', # http://tools.ietf.org/html/rfc3834
      'X-Auto-Response-Suppress' => 'OOF'
    )
  end
end
