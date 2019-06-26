module AlaveteliPro
  ##
  # A mailer responsible for sending out webhook information to the Pro contact
  #
  class WebhookMailer < ApplicationMailer
    def digest(webhooks)
      @customer_webhooks = webhooks.sort_by(&:date).group_by(&:customer_id)

      set_auto_generated_headers

      subject = _(
        "{{pro_site_name}} webhook daily digest",
        pro_site_name: AlaveteliConfiguration.pro_site_name.html_safe
      )
      mail_pro_team(subject)
    end

    private

    def mail_pro_team(subject)
      mail(
        from: pro_contact_from_name_and_email,
        to: pro_contact_from_name_and_email,
        subject: subject
      )
    end
  end
end
