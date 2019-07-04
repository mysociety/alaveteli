module AlaveteliPro
  ##
  # A mailer responsible for sending out the weekly metrics report to
  # the Pro contact
  #
  class MetricsMailer < ApplicationMailer
    require_relative '../../../lib/alaveteli_pro/metrics_report.rb'

    def self.send_weekly_report
      weekly_report(AlaveteliPro::MetricsReport.new.report_data,
                    pricing_enabled?).deliver_now
    end

    def weekly_report(data, pricing_enabled = false)
      @data = data
      @pricing_enabled = pricing_enabled

      set_auto_generated_headers

      subject = _("{{pro_site_name}} Weekly Metrics",
                  pro_site_name: AlaveteliConfiguration.pro_site_name.html_safe)

      mail(from: pro_contact_from_name_and_email,
           to: pro_contact_from_name_and_email,
           subject: subject
          )
    end

    private

    def self.pricing_enabled?
      feature_enabled?(:pro_pricing) == true
    end
  end
end
