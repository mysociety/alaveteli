require 'spec_helper'

RSpec.describe AlaveteliPro::Price do
  let(:price) { double(:price, unit_amount: 833) }
  subject { described_class.new(price) }

  describe '.list' do
    before { described_class.instance_variable_set(:@list, nil) }

    let(:price_ids) { %w[price_1 price_2 price_3] }
    let(:price_1) { double('AlaveteliPro::Price') }
    let(:price_2) { double('AlaveteliPro::Price') }

    before do
      allow(AlaveteliConfiguration).to receive(:stripe_price_ids).
        and_return(price_ids)
      allow(described_class).to receive(:retrieve).with('price_1').
        and_return(price_1)
      allow(described_class).to receive(:retrieve).with('price_2').
        and_return(price_2)
      allow(described_class).to receive(:retrieve).with('price_3').
        and_return(nil)
    end

    it 'returns a list of retrieved prices' do
      expect(described_class.list).to eq([price_1, price_2])
    end
  end

  describe '.retrieve' do
    it 'retrieves a price from Stripe' do
      stripe_price = double('stripe_price')
      allow(Stripe::Price).to receive(:retrieve).with('test_pro').
        and_return(stripe_price)
      allow(described_class).to receive(:add_stripe_namespace).with('pro').
        and_return('test_pro')

      price = described_class.retrieve('pro')
      expect(price).to be_an_instance_of(described_class)
    end

    it 'returns nil if Stripe::InvalidRequestError is raised' do
      allow(Stripe::Price).to receive(:retrieve).
        and_raise(Stripe::InvalidRequestError.new('', ''))

      expect(described_class.retrieve('invalid')).to be_nil
    end
  end

  describe '#to_param' do
    it 'removes the stripe namespace from the id' do
      price = described_class.new(double('stripe_price', id: 'test_pro'))
      allow(price).to receive(:remove_stripe_namespace).with('test_pro').
        and_return('pro')

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
