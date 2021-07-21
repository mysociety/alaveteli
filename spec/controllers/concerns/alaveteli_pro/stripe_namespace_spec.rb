require 'spec_helper'

RSpec.describe AlaveteliPro::StripeNamespace do
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

    describe '#remove_stripe_namespace' do
      it 'removes namespace from string' do
        expect(remove_stripe_namespace('namespace-string')).to eq('string')
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

    describe '#remove_stripe_namespace' do
      it 'return string' do
        expect(remove_stripe_namespace('string')).to eq('string')
      end
    end

  end

end
