require 'spec_helper'
require 'stripe_mock'

RSpec.describe AlaveteliPro::Customer do
  describe '.retrieve' do
    it 'returns a new customer instance when successful' do
      stripe_customer = double('Stripe::Customer')
      allow(Stripe::Customer).to receive(:retrieve).with('cus_123').
        and_return(stripe_customer)

      customer = described_class.retrieve('cus_123')
      expect(customer).to be_an_instance_of(described_class)
      expect(customer).to eq(stripe_customer)
    end

    it 'raises Stripe::InvalidRequestError when customer does not exist' do
      StripeMock.start

      error = Stripe::InvalidRequestError.new('', '')
      StripeMock.prepare_error(error)

      expect { described_class.retrieve('cus_123') }.to raise_error(
        Stripe::InvalidRequestError
      )

      StripeMock.stop
    end
  end

  describe '#default_source' do
    let(:stripe_customer) do
      double('Stripe::Customer', default_source: 'card_123')
    end

    let(:customer) { described_class.new(stripe_customer) }

    it 'returns the default source from the customer sources' do
      source1 = double('Stripe::Card', id: 'card_123')
      source2 = double('Stripe::Card', id: 'card_456')
      allow(customer).to receive(:sources).and_return([source1, source2])

      expect(customer.default_source).to eq(source1)
    end

    it 'memoizes the default source' do
      source = double('Stripe::Card', id: 'card_123')
      expect(customer).to receive(:sources).once.and_return([source])
      2.times { expect(customer.default_source) }
    end
  end
end
