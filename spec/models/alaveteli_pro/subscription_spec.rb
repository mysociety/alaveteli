require 'spec_helper'

RSpec.describe AlaveteliPro::Subscription do

  let(:object) { Stripe::Subscription.new }
  let(:subscription) { described_class.new(object) }

  describe '#active?' do

    it 'should return true if status is active' do
      object.status = 'active'
      expect(subscription.active?).to eq true
    end

    it 'should return false if status is not active' do
      object.status = 'other'
      expect(subscription.active?).to eq false
    end

  end

  describe 'missing methods' do

    it 'should delegate methods to object' do
      mock_coupon = double(:coupon)
      expect { subscription.coupon }.to raise_error(NoMethodError)
      expect { subscription.coupon = mock_coupon }.to_not raise_error
      expect(subscription.coupon).to eq mock_coupon
      expect(subscription.__getobj__.coupon).to eq mock_coupon
    end

  end

end
