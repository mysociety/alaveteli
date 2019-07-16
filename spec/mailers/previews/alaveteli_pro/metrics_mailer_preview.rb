require 'rspec/mocks/standalone'

module AlaveteliPro
  class MetricsMailerPreview < ActionMailer::Preview
    def weekly_report
      data =
        {
          new_pro_requests: 104,
          estimated_total_pro_requests: 37535,
          new_batches: 3,
          new_signups: 5,
          total_accounts: 284,
          active_accounts: 42,
          paying_users: 44,
          discounted_users: 7,
          trialing_users: 8,
          past_due_users: { count: 0, subs: 0 },
          pending_cancellations:
            { count: 2, subs: ['sub_1234', 'sub_1235'] },
          unknown_users: 0,
          new_and_returning_users:
            { count: 6,
              subs:
                ['sub_1236',
                 'sub_1237',
                 'sub_1238',
                 'sub_1239',
                 'sub_1240',
                 'sub_1241'] },
          canceled_users: { count: 0, subs: [] }
        }

      report = MetricsReport.new
      report.stub(report_data: data)

      MetricsMailer.weekly_report(report)
    end
  end
end
