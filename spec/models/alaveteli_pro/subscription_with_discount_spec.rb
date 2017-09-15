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

      expect(subject.amount).to eq(416)
    end

    it 'applies an amount_off discount correctly' do
      coupon = OpenStruct.new(id: "2_off", amount_off: 200, valid: true)
      subject = described_class.new(mock_subscription(coupon))

      expect(subject.amount).to eq(633)
    end

  end

  describe '#discounted?' do

    context 'there is no discount' do

      it 'returns false' do
        expect(subject.discounted?).to be false
      end

    end

    context 'the discount is invalid' do

      it 'returns false' do
        coupon = OpenStruct.new(id: "50_off", percent_off: 50, valid: false)
        subject = described_class.new(mock_subscription(coupon))

        expect(subject.discounted?).to be false
      end

    end

    context 'a valid discount applies' do

      it 'returns true' do
        coupon = OpenStruct.new(id: "50_off", percent_off: 50, valid: true)
        subject = described_class.new(mock_subscription(coupon))

        expect(subject.discounted?).to be true
      end

    end

  end

  describe '#free?' do

    context 'the price is > 0' do

      it 'returns false' do
        coupon = OpenStruct.new(id: "50_off", percent_off: 50, valid: true)
        subject = described_class.new(mock_subscription(coupon))

        expect(subject.free?).to be false
      end

    end

    context 'there is a 100% discount' do

      it 'returns true' do
        coupon = OpenStruct.new(id: "100_off", percent_off: 100, valid: true)
        subject = described_class.new(mock_subscription(coupon))

        expect(subject.free?).to be true
      end

    end

    context 'there is a discount that zeros the price' do

      it 'returns true' do
        coupon = OpenStruct.new(id: "833_off", amount_off: 833, valid: true)
        subject = described_class.new(mock_subscription(coupon))

        expect(subject.free?).to be true
      end

    end

  end

end
