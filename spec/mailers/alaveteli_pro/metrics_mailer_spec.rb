require 'spec_helper'

RSpec.describe AlaveteliPro::MetricsMailer do
  let(:data) do
    {
      new_pro_requests: 104,
      estimated_total_pro_requests: 37_535,
      new_batches: 3,
      new_signups: 5,
      total_accounts: 284,
      active_accounts: 42,
      expired_embargoes: 17,
      paying_users: 44,
      discounted_users: 7,
      trialing_users: 8,
      past_due_users: { count: 0, subs: 0 },
      pending_cancellations:
        { count: 2, subs: %w[sub_1234 sub_1235] },
      unknown_users: 0,
      new_and_returning_users:
        { count: 6,
          subs:
            %w[sub_1236
               sub_1237
               sub_1238
               sub_1239
               sub_1240
               sub_1241] },
      canceled_users: { count: 0, subs: [] }
    }
  end

  let(:report) do
    report = AlaveteliPro::MetricsReport.new
    allow(report).to receive(:report_data).and_return(data)
    report
  end

  let(:message) { AlaveteliPro::MetricsMailer.weekly_report(report).message }

  describe '.send_weekly_report' do
    subject { described_class.send_weekly_report(report) }

    it 'should deliver the weekly_report email' do
      expect { subject }.to(
        change(ActionMailer::Base.deliveries, :size).by(1)
      )
    end
  end

  describe '#weekly_report' do
    it 'sends the email to the pro contact address' do
      expect(message.to).to eq [AlaveteliConfiguration.pro_contact_email]
    end

    it 'sends the email from the pro contact address' do
      expect(message.from).to eq [AlaveteliConfiguration.pro_contact_email]
    end

    it 'has a subject including "Weekly Metrics"' do
      expect(message.subject).to match('Weekly Metrics')
    end

    it 'includes the number of Pro accounts' do
      expect(message.body).to include('Total number of Pro accounts: 284')
    end

    it 'includes the number of active accounts' do
      expect(message.body).to include(
        'Number of Pro accounts active this week: 42'
      )
    end

    it 'includes the number of expired embargoes' do
      expect(message.body).to include(
        'Number of expired embargoes this week: 17'
      )
    end

    it 'includes the number of new batch requests' do
      expect(message.body).to include('New batches made this week: 3')
    end

    it 'includes the number of new pro requests' do
      expect(message.body).to include('New Pro requests this week: 104')
    end

    it 'includes the estimated total pro requests' do
      expect(message.body).to include(
        'Estimated total number of Pro requests: 37535'
      )
    end

    context 'pro pricing disabled' do
      it 'does not include paying user info' do
        expect(message.body).to_not include('Number of paying users: 44')
      end

      it 'reports the number of new Pro accounts' do
        expect(message.body).to include('New Pro accounts this week: 5')
      end

      it 'does not report the number of new Pro subscriptions' do
        expect(message.body).to_not include('New Pro subscriptions this week:')
      end
    end

    context 'pro pricing enabled', feature: :pro_pricing do
      it 'reports the number of new Pro subscriptions' do
        expect(message.body).to include('New Pro subscriptions this week: 6')
      end

      it 'does not report the number of new Pro accounts' do
        expect(message.body).to_not include('New Pro accounts this week:')
      end

      it 'includes paying user info' do
        expect(message.body).to include('Number of paying users: 44')
      end

      describe 'returning subscribers' do
        it 'correctly calculates the number of returning subscribers' do
          expect(message.body).
            to include('(includes 1 returning subscriber)')
        end

        it 'pluralises "subscriber"' do
          data[:new_and_returning_users][:count] = 7
          expect(message.body).
            to include('(includes 2 returning subscribers)')
        end

        it 'does not show the returning subscribers note if there are none' do
          data[:new_and_returning_users][:count] = 5
          expect(message.body).
            to_not include('(includes 0 returning subscriber')
        end
      end

      describe 'listing subscriber dashboard links' do
        it 'should include an indented bullet point list' do
          expect(message.body).to include(
            <<~TXT
              Pending cancellations: 2
                * https://dashboard.stripe.com/subscriptions/sub_1234
                * https://dashboard.stripe.com/subscriptions/sub_1235
            TXT
          )
        end

        it 'should not include a list if there are no pending cancellations' do
          data[:pending_cancellations][:count] = 0
          data[:pending_cancellations][:subs] = 0
          expect(message.body).to include(
            <<~TXT
              Pending cancellations: 0

            TXT
          )
        end
      end
    end
  end
end
