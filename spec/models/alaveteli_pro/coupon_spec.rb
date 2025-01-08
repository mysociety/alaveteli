require 'spec_helper'

RSpec.describe AlaveteliPro::Coupon do
  describe '.referral' do
    before { described_class.instance_variable_set(:@referral, nil) }

    it 'returns a coupon for the referral configuration' do
      stripe_coupon = double('Stripe::Coupon')
      allow(AlaveteliConfiguration).to receive(:pro_referral_coupon).
        and_return('REFERRAL')
      allow(described_class).to receive(:add_stripe_namespace).
        and_return('namespace_REFERRAL')
      allow(Stripe::Coupon).to receive(:retrieve).with('namespace_REFERRAL').
        and_return(stripe_coupon)

      expect(described_class.referral).to be_an_instance_of(described_class)
      expect(described_class.referral).to eq(stripe_coupon)
    end

    it 'returns nil if no referral coupon is configured' do
      allow(AlaveteliConfiguration).to receive(:pro_referral_coupon).
        and_return(nil)

      expect(described_class.referral).to be_nil
    end
  end

  describe '.retrieve' do
    it 'retrieves a Stripe coupon and wraps it' do
      stripe_coupon = double('Stripe::Coupon')
      allow(Stripe::Coupon).to receive(:retrieve).and_return(stripe_coupon)
      allow(described_class).to receive(:add_stripe_namespace).
        and_return('namespace_ID')

      coupon = described_class.retrieve('ID')
      expect(coupon).to be_a(described_class)
      expect(coupon.__getobj__).to eq(stripe_coupon)
    end

    it 'returns nil if the coupon is not found' do
      allow(Stripe::Coupon).to receive(:retrieve).
        and_raise(Stripe::InvalidRequestError.new('', ''))

      expect(described_class.retrieve('NONEXISTENT')).to be_nil
    end
  end

  describe '#to_param' do
    it 'removes the stripe namespace from the id' do
      coupon = described_class.new(double('Stripe::Coupon', id: 'namespace_ID'))
      allow(coupon).to receive(:remove_stripe_namespace).and_return('ID')

      expect(coupon.to_param).to eq('ID')
    end
  end

  describe '#terms' do
    it 'returns humanized terms from metadata if present' do
      coupon = described_class.new(
        double(
          'Stripe::Coupon',
          metadata: double(humanized_terms: 'Human readable terms')
        )
      )

      expect(coupon.terms).to eq('Human readable terms')
    end

    it 'returns name if humanized terms are not present' do
      coupon = described_class.new(
        double(
          'Stripe::Coupon',
          metadata: double(humanized_terms: nil),
          name: 'Coupon Name'
        )
      )

      expect(coupon.terms).to eq('Coupon Name')
    end
  end
end
