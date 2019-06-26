require 'spec_helper'
require 'stripe_mock'

describe AlaveteliPro::MetricsReport do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:stripe_helper) { StripeMock.create_test_helper }
  let!(:pro_plan) { stripe_helper.create_plan(id: 'pro', amount: 10) }

  let!(:pro_annual_plan) do
    stripe_helper.create_plan(id: 'pro-annual-billing', amount: 100)
  end

  describe '#report_data' do
    subject { described_class.new.report_data }

    let(:user) { FactoryBot.create(:user) }
    let(:pro_user) { FactoryBot.create(:pro_user) }

    before do
      2.times { FactoryBot.create(:info_request, user: user) }
      3.times { FactoryBot.create(:info_request, user: pro_user) }
      FactoryBot.create(:info_request_batch,
                        :sent,
                        :embargoed,
                        user: pro_user)

      time_travel_to(2.weeks.ago) {
        pro = FactoryBot.create(:pro_user)
        FactoryBot.create(:info_request, user: pro)
      }
    end

    context 'without pricing enabled' do
      it 'does not calculate Stripe data' do
        expect(subject).to_not include(:paying_users)
      end
    end

    context 'with pricing enabled', feature: :pro_pricing do
      it 'includes Stripe data' do
        expect(subject).to include(:paying_users)
      end
    end

    it { is_expected.to be_a(Hash) }

    it 'does not include non-pro requests in requests made count' do
      expect(subject[:new_pro_requests]).to eq 4
    end

    it 'does not include non-pro requests in requests made count' do
      expect(subject[:new_pro_requests]).to eq 4
    end

    it 'returns the total number of Pro requests' do
      expect(subject[:total_new_requests]).to eq 5
    end

    it 'returns the number of batch requests' do
      expect(subject[:new_batches]).to eq 1
    end

    it 'returns the number of new Pro accounts' do
      expect(subject[:new_signups]).to eq 1
    end

    it 'returns the number of Pro accounts' do
      expect(subject[:total_accounts]).to eq 2
    end

    it 'does not include non-pro activity in the active user count' do
      expect(subject[:active_accounts]).to eq 1
    end
  end

  describe '#stripe_report_data' do
    subject { described_class.new.stripe_report_data }

    it { is_expected.to be_a(Hash) }

    context 'with pricing disabled' do
      it { is_expected.to eq({}) }
    end

    context 'with pricing enabled', feature: :pro_pricing do
      let(:customer) do
        Stripe::Customer.create(email: 'user@localhost',
                                source: stripe_helper.generate_card_token)
      end

      let(:coupon) do
        stripe_helper.create_coupon(id: 'half_off',
                                    percent_off: 50,
                                    duration: 'forever')
      end

      let!(:paid_sub) do
        Stripe::Subscription.create(customer: customer,
                                    plan: pro_plan.id)
      end

      let!(:paid_annual_sub) do
        Stripe::Subscription.create(customer: customer,
                                    plan: pro_annual_plan.id)
      end

      let!(:half_price_sub) do
        Stripe::Subscription.create(customer: customer,
                                    plan: pro_plan.id,
                                    coupon: coupon.id)
      end

      let!(:trial_sub) do
        Stripe::Subscription.create(customer: customer,
                                    plan: pro_plan.id,
                                    trial_period_days: 360,
                                    trial_end: (Time.now + 9.days).to_i)
      end

      let!(:pending_cancel_sub) do
        subscription = Stripe::Subscription.create(customer: customer,
                                                   plan: pro_plan.id)

        # note - in later API versions, at_period_end is no longer
        # available for delete so we'd have to call something like
        # this instead:
        # Stripe::Subscription.update(subscription.id,
        #                             cancel_at_period_end: true)
        subscription.delete(at_period_end: true)
        subscription
      end

      let!(:past_due_sub) do
        subscription = Stripe::Subscription.create(customer: customer,
                                                   plan: pro_plan.id,)
        StripeMock.mark_subscription_as_past_due(subscription)
        subscription
      end

      it 'returns the number of users paying the full rate' do
        expect(subject[:paying_users]).to eq 2
      end

      it 'returns the number of discounted users' do
        expect(subject[:discounted_users]).to eq 1
      end

      it 'returns the number of trialing users' do
        expect(subject[:trialing_users]).to eq 1
      end

      describe 'returning pending cancellation data' do
        it 'returns the number of users with pending cancellations' do
          expect(subject[:pending_cancellations][:count]).to eq 1
        end

        it 'returns the subscriber ids of users with pending cancellations' do
          expect(subject[:pending_cancellations][:subs]).
            to eq([pending_cancel_sub.id])
        end
      end

      describe 'returning past due data' do
        it 'returns the number of past due users' do
          expect(subject[:past_due_users][:count]).to eq 1
        end

        it 'returns the subscriber ids of past due users' do
          expect(subject[:past_due_users][:subs]).to eq([past_due_sub.id])
        end
      end

      describe 'returning new Stripe user data' do
        it 'returns the number of new Stripe users' do
          expect(subject[:new_and_returning_users][:count]).to eq 6
        end

        it 'returns the subscriber ids of new Stripe users' do
          expected =
            [ paid_sub.id, paid_annual_sub.id, half_price_sub.id,
              trial_sub.id, pending_cancel_sub.id, past_due_sub.id ]
          expect(subject[:new_and_returning_users][:subs]).
            to match_array(expected)
        end
      end

      describe 'returning cancelled user data' do
        let(:unrelated_plan) do
          stripe_helper.create_plan(id: 'not_ours', amount: 4)
        end

        before do
          StripeMock.mock_webhook_event('customer.subscription.deleted',
                                        plan: pro_plan)
          StripeMock.mock_webhook_event('customer.subscription.deleted',
                                        plan: pro_annual_plan)
          StripeMock.mock_webhook_event('customer.subscription.deleted',
                                        plan: unrelated_plan)
        end

        it 'returns the number of cancelled users' do
          expect(subject[:canceled_users][:count]).to eq 2
        end

        it 'returns the subscription ids for cancelled users' do
          expect(subject[:canceled_users][:subs]).
            to eq(['su_00000000000000', 'su_00000000000000'])
        end
      end
    end
  end
end
