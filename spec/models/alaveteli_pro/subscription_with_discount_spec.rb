require 'spec_helper'

RSpec.describe AlaveteliPro::SubscriptionWithDiscount do
  let(:plan) { double(:plan, amount: 833) }
  let(:coupon) { nil }
  let(:trial) { nil }
  let(:subscription) do
    discount = double(:coupon, coupon: coupon) if coupon
    trial_start = Time.now.to_i if trial
    trial_end = trial_start + 1 if trial
    double(:subscription, plan: plan, discount: discount,
                          trial_start: trial_start, trial_end: trial_end)
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
        double(:coupon, id: '50_off', amount_off: nil,
                        percent_off: 50, valid: true)
      end

      it 'applies a percentage discount correctly' do
        expect(subject.amount).to eq(416)
      end
    end

    context 'with fixed amount coupon' do
      let(:coupon) do
        double(:coupon, id: '2_off', amount_off: 200, valid: true)
      end

      it 'applies an amount_off discount correctly' do
        expect(subject.amount).to eq(633)
      end
    end

    context 'on a trial' do
      let(:trial) { true }

      it 'returns 0' do
        expect(subject.amount).to eq(0)
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
        double(:coupon, id: '50_off', valid: false)
      end

      it 'returns false' do
        expect(subject.discounted?).to be false
      end
    end

    context 'a valid discount applies' do
      let(:coupon) do
        double(:coupon, id: '50_off', amount_off: nil,
                        percent_off: 50, valid: true)
      end

      it 'returns true' do
        expect(subject.discounted?).to be true
      end
    end

    context 'on a trial' do
      let(:trial) { true }

      it 'returns true' do
        expect(subject.discounted?).to be true
      end
    end

  end

  describe '#discount_name' do

    context 'no discount is set' do
      it { expect(subject.discount_name).to be_nil }
    end

    context 'with a coupon' do
      let(:coupon) do
        double(:coupon, id: 'COUPON_ID', valid: true)
      end

      it 'returns ID of coupon' do
        expect(subject.discount_name).to eq('COUPON_ID')
      end
    end

    context 'on a trial' do
      let(:trial) { true }

      it 'returns PROBETA' do
        expect(subject.discount_name).to eq('PROBETA')
      end
    end

  end

  describe '#free?' do

    context 'the price is > 0' do
      let(:coupon) do
        double(:coupon, id: '50_off', amount_off: nil,
                        percent_off: 50, valid: true)
      end

      it 'returns false' do
        expect(subject.free?).to be false
      end
    end

    context 'there is a 100% discount' do
      let(:coupon) do
        double(:coupon, id: '100_off', amount_off: nil,
                        percent_off: 100, valid: true)
      end

      it 'returns true' do
        expect(subject.free?).to be true
      end
    end

    context 'there is a discount that zeros the price' do
      let(:coupon) do
        double(:coupon, id: '833_off', amount_off: 833, valid: true)
      end

      it 'returns true' do
        expect(subject.free?).to be true
      end
    end

    context 'on a trial' do
      let(:trial) { true }

      it 'returns true' do
        expect(subject.free?).to be true
      end
    end

  end

end
