require 'spec_helper'

RSpec.describe StripeHelper do
  describe '#stripe_locale' do
    subject { helper.stripe_locale }

    before do
      allow(AlaveteliLocalization).to receive(:locale).and_return(locale)
    end

    context 'current local supported by Stripe' do
      let(:locale) { 'en' }
      it { is_expected.to eq 'en' }
    end

    context 'current local not supported by Stripe' do
      let(:locale) { 'cy' }
      it { is_expected.to eq 'auto' }
    end
  end
end
