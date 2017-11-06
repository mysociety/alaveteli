# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::SubscriptionWithDiscount do
  let(:plan) { OpenStruct.new(amount: 833) }
  let(:coupon) { nil }
  let(:trial) { nil }
  let(:subscription) do
    discount = OpenStruct.new(coupon: coupon) if coupon
    OpenStruct.new(plan: plan, discount: discount)
  end

  subject { described_class.new(subscription) }

  describe '#amount' do

    context 'no discount is set' do
      it 'returns the original stripe plan amount' do
        expect(subject.amount).to eq(833)
      end
    end

    context 'with percentage coupon' do
      let(:coupon) do
        OpenStruct.new(id: '50_off', percent_off: 50, valid: true)
      end

      it 'applies a percentage discount correctly' do
        expect(subject.amount).to eq(416)
      end
    end

    context 'with fixed amount coupon' do
      let(:coupon) do
        OpenStruct.new(id: '2_off', amount_off: 200, valid: true)
      end

      it 'applies an amount_off discount correctly' do
        expect(subject.amount).to eq(633)
      end
    end

  end

  describe '#discounted?' do

    context 'there is no discount' do
      it 'returns false' do
        expect(subject.discounted?).to be false
      end
    end

    context 'the discount is invalid' do
      let(:coupon) do
        OpenStruct.new(id: '50_off', percent_off: 50, valid: false)
      end

      it 'returns false' do
        expect(subject.discounted?).to be false
      end
    end

    context 'a valid discount applies' do
      let(:coupon) do
        OpenStruct.new(id: '50_off', percent_off: 50, valid: true)
      end

      it 'returns true' do
        expect(subject.discounted?).to be true
      end
    end

  end

  describe '#free?' do

    context 'the price is > 0' do
      let(:coupon) do
        OpenStruct.new(id: '50_off', percent_off: 50, valid: true)
      end

      it 'returns false' do
        expect(subject.free?).to be false
      end
    end

    context 'there is a 100% discount' do
      let(:coupon) do
        OpenStruct.new(id: '100_off', percent_off: 100, valid: true)
      end

      it 'returns true' do
        expect(subject.free?).to be true
      end
    end

    context 'there is a discount that zeros the price' do
      let(:coupon) do
        OpenStruct.new(id: '833_off', amount_off: 833, valid: true)
      end

      it 'returns true' do
        expect(subject.free?).to be true
      end
    end

  end

end
