# == Schema Information
#
# Table name: webhooks
#
#  id          :integer          not null, primary key
#  params      :jsonb
#  notified_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

RSpec.describe Webhook, type: :model do
  let(:webhook) { FactoryBot.build(:webhook) }

  describe 'validations' do
    specify { expect(webhook).to be_valid }

    it 'requires params' do
      webhook.params = nil
      expect(webhook).not_to be_valid
    end
  end

  describe '.pending_notification' do
    subject { Webhook.pending_notification }

    it 'includes webhooks if notified_at is nil' do
      webhook = FactoryBot.create(:webhook, notified_at: nil)
      is_expected.to include webhook
    end

    it 'excludes webhooks if notified_at is set' do
      webhook = FactoryBot.create(:webhook, notified_at: Time.zone.now)
      is_expected.to_not include webhook
    end
  end

  describe '#date' do
    it 'returns nil if there is not a created parameter' do
      webhook.params = { 'created' => nil }
      expect(webhook.date).to be_nil
    end

    it 'returns created parameter and typecast as Time' do
      time = Time.now.utc.change(usec: 0)
      webhook.params = { 'created' => time.to_i }
      expect(webhook.date).to eq time
    end
  end

  describe '#customer_id' do
    it 'returns nil if there is not a data parameter' do
      webhook.params = { 'data' => nil }
      expect(webhook.date).to be_nil
    end

    it 'returns nil if there is not a data.object parameter' do
      webhook.params = { 'data' => { 'object' => nil } }
      expect(webhook.date).to be_nil
    end

    it 'returns nil if there is not a data.object.customer parameter' do
      webhook.params = { 'data' => { 'object' => { 'customer' => nil } } }
      expect(webhook.date).to be_nil
    end

    it 'returns data.object.customer parameter' do
      webhook.params = { 'data' => { 'object' => { 'customer' => 'cus_123' } } }
      expect(webhook.customer_id).to eq 'cus_123'
    end
  end

  describe '#state' do
    subject { webhook.state }

    let(:fixture) { nil }
    let(:webhook) { FactoryBot.build(:webhook, fixture: fixture) }

    it { is_expected.to eq 'Unknown webhook (evt_123)' }

    context 'coupon-code-applied' do
      let(:fixture) { 'coupon-code-applied' }
      it { is_expected.to eq 'Coupon code "COUPON-123" applied' }
    end

    context 'coupon-code-revoked' do
      let(:fixture) { 'coupon-code-revoked' }
      it { is_expected.to eq 'Coupon code "COUPON-123" revoked' }
    end

    context 'plan-changed' do
      let(:fixture) { 'plan-changed' }
      it { is_expected.to eq 'Plan changed from "Pro" to "Pro Annual Billing"' }
    end

    context 'subscription-cancelled' do
      let(:fixture) { 'subscription-cancelled' }
      it { is_expected.to eq 'Subscription cancelled' }
    end

    context 'subscription-reactivated' do
      let(:fixture) { 'subscription-reactivated' }
      it { is_expected.to eq 'Subscription reactivated' }
    end

    context 'subscription-renewal-failure' do
      let(:fixture) { 'subscription-renewal-failure' }
      it { is_expected.to eq 'Subscription renewal failure' }
    end

    context 'subscription-renewal-repeated-failure' do
      let(:fixture) { 'subscription-renewal-repeated-failure' }
      it { is_expected.to eq 'Subscription renewal repeated failure' }
    end

    context 'subscription-renewed-after-failure' do
      let(:fixture) { 'subscription-renewed-after-failure' }
      it { is_expected.to eq 'Subscription renewed after failure' }
    end

    context 'subscription-renewed' do
      let(:fixture) { 'subscription-renewed' }
      it { is_expected.to eq 'Subscription renewed' }
    end

    context 'trial-cancelled' do
      let(:fixture) { 'trial-cancelled' }
      it { is_expected.to eq 'Trial cancelled' }
    end

    context 'trial-ended-first-payment-failed' do
      let(:fixture) { 'trial-ended-first-payment-failed' }
      it { is_expected.to eq 'Trial ended, first payment failed' }
    end

    context 'trial-extended' do
      let(:fixture) { 'trial-extended' }
      it { is_expected.to eq 'Trial extended' }
    end
  end
end
