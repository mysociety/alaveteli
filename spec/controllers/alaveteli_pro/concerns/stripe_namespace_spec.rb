require 'spec_helper'

describe AlaveteliPro::StripeNamespace do
  include AlaveteliPro::StripeNamespace

  context 'with namespace' do

    before(:each) do
      allow(AlaveteliConfiguration).to receive(:stripe_namespace).
        and_return('namespace')
    end

    describe '#add_stripe_namespace' do
      it 'prepend namespace to string' do
        expect(add_stripe_namespace('string')).to eq('namespace-string')
      end
    end

  end

  context 'without namespace' do

    before(:each) do
      allow(AlaveteliConfiguration).to receive(:stripe_namespace).
        and_return('')
    end

    describe '#add_stripe_namespace' do
      it 'return string' do
        expect(add_stripe_namespace('string')).to eq('string')
      end
    end

  end

end
