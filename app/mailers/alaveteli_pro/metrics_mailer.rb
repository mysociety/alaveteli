module AlaveteliPro
  ##
  # A mailer responsible for sending out the weekly metrics report to
  # the Pro contact
  #
  class MetricsMailer < ApplicationMailer
    def self.send_weekly_report(report = AlaveteliPro::MetricsReport.new)
      weekly_report(report).deliver_now
    end

    def weekly_report(report)
      @data = report.report_data
      @pricing_enabled = report.includes_pricing_data?
      @report_start = report.report_start
      @report_end = report.report_end

      set_auto_generated_headers

      subject = _("{{pro_site_name}} Weekly Metrics",
                  pro_site_name: AlaveteliConfiguration.pro_site_name.html_safe)

      mail(from: pro_contact_from_name_and_email,
           to: pro_contact_from_name_and_email,
           subject: subject)
    end
  end
end
