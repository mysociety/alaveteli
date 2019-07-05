module AlaveteliPro
  class MetricsMailerPreview < ActionMailer::Preview
    def weekly_report_pricing
      data = AlaveteliPro::MetricsReport.new.report_data
      MetricsMailer.weekly_report(data, true)
    end

    def weekly_report_no_pricing
      data = AlaveteliPro::MetricsReport.new.report_data
      MetricsMailer.weekly_report(data, false)
    end
  end
end
