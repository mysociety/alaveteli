require 'spec_helper'

RSpec.describe AlaveteliPro::Price do
  let(:price) { double(:price, unit_amount: 833) }
  subject { described_class.new(price) }

  describe '.list' do
    before { described_class.instance_variable_set(:@list, nil) }

    let(:prices) { { 'price_1' => 'pro', 'price_2' => 'price_2' } }
    let(:price_1) { AlaveteliPro::Price.new(double('Stripe::Price')) }
    let(:price_2) { AlaveteliPro::Price.new(double('Stripe::Price')) }

    before do
      allow(AlaveteliConfiguration).to receive(:stripe_prices).
        and_return(prices)
      allow(described_class).to receive(:retrieve).with('pro').
        and_return(price_1)
      allow(described_class).to receive(:retrieve).with('price_2').
        and_return(price_2)
    end

    it 'returns a list of retrieved prices' do
      expect(described_class.list).to eq([price_1, price_2])
    end
  end

  describe '.retrieve' do
    it 'retrieves a price from Stripe' do
      stripe_price = double('stripe_price')
      allow(Stripe::Price).to receive(:retrieve).with('pro').
        and_return(stripe_price)
      price = described_class.retrieve('pro')
      expect(price).to be_an_instance_of(described_class)
    end
  end

  describe '#to_param' do
    it 'returns the configured key for the id' do
      allow(AlaveteliConfiguration).to receive(:stripe_prices).
        and_return('price_123' => 'pro')

      price = described_class.new(double('stripe_price', id: 'price_123'))

      expect(price.to_param).to eq('pro')
    end
  end

  describe '#product' do
    let(:stripe_price) { double('stripe_price', product: 'prod_123') }
    let(:price) { described_class.new(stripe_price) }

    it 'retrieves the product from Stripe' do
      product = double('product')
      allow(Stripe::Product).to receive(:retrieve).with('prod_123').
        and_return(product)

      expect(price.product).to eq(product)
    end

    it 'memoizes the result' do
      expect(Stripe::Product).to receive(:retrieve).once.
        and_return(double('product'))
      2.times { price.product }
    end

    it 'returns nil if there is no product_id' do
      allow(stripe_price).to receive(:product).and_return(nil)

      expect(price.product).to be_nil
    end
  end

  describe '#unit_amount_with_tax' do
    context 'with the default tax rate' do
      it 'adds 20% tax to the price unit_amount' do
        expect(subject.unit_amount_with_tax).to eq(1000)
      end
    end

    context 'with a custom tax rate' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:stripe_tax_rate).and_return('0.25')
      end

      it 'adds 25% tax to the price unit_amount' do
        expect(subject.unit_amount_with_tax).to eq(1041)
      end
    end
  end

  it 'delegates to the stripe price' do
    expect(subject.unit_amount).to eq(833)
  end

  describe '#tax_percent' do
    it 'returns the tax rate as a percentage' do
      allow(AlaveteliConfiguration).to receive(:stripe_tax_rate).
        and_return('0.20')
      expect(subject.tax_percent).to eq(20.0)
    end
  end
end
