# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::SubscriptionWithDiscount do
  let(:plan) { OpenStruct.new(amount: 833) }
  let(:subscription) { OpenStruct.new(plan: plan, discount: nil) }
  subject { described_class.new(subscription) }

  def mock_subscription(coupon)
    discount = OpenStruct.new(coupon: coupon)
    OpenStruct.new(plan: plan, discount: discount)
  end

  describe '#amount' do

    context 'no discount is set' do

      it 'returns the original stripe plan amount' do
        expect(subject.amount).to eq(833)
      end

    end

    it 'applies a percentage discount correctly' do
      coupon = OpenStruct.new(id: "50_off", percent_off: 50, valid: true)
      subject = described_class.new(mock_subscription(coupon))

      expect(subject.amount).to eq(416.5)
    end

    it 'applies an amount_off discount correctly' do
      coupon = OpenStruct.new(id: "2_off", amount_off: 200, valid: true)
      subject = described_class.new(mock_subscription(coupon))

      expect(subject.amount).to eq(633.0)
    end

  end

end
