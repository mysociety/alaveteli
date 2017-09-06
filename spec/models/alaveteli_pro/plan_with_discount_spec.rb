# -*- encoding : utf-8 -*-
require 'spec_helper'

describe AlaveteliPro::PlanWithDiscount do
  let(:plan) { OpenStruct.new(amount: 833) }
  let(:subscription) { OpenStruct.new(plan: plan, discount: nil) }
  subject { described_class.new(subscription) }

  describe '#amount' do

    context 'no discount is set' do
      it 'returns the original stripe plan amount' do
        expect(subject.amount).to eq(833)
      end
    end

    it 'applies a percentage discount correctly' do
      coupon = OpenStruct.new(id: "50_off", object: "coupon", percent_off: 50,
                              duration: "forever", valid: true)
      discount = OpenStruct.new(coupon: coupon)
      subscription = OpenStruct.new(plan: plan, discount: discount)
      subject = described_class.new(subscription)

      expect(subject.amount).to eq(416.5)
    end

    it 'applies an amount_off discount correctly' do
      coupon = OpenStruct.new(id: "2_off", object: "coupon", amount_off: 200,
                              duration: "forever", valid: true)
      discount = OpenStruct.new(coupon: coupon)
      subscription = OpenStruct.new(plan: plan, discount: discount)
      subject = described_class.new(subscription)

      expect(subject.amount).to eq(633.0)
    end

  end

end
