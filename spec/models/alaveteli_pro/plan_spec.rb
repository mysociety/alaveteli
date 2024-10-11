require 'spec_helper'

RSpec.describe AlaveteliPro::Plan do
  let(:plan) { double(:plan, amount: 833) }
  subject { described_class.new(plan) }

  describe '.list' do
    before { described_class.instance_variable_set(:@list, nil) }

    it 'returns an array with one pro plan' do
      pro_plan = double('pro_plan')
      allow(described_class).to receive(:retrieve).with('pro').
        and_return(pro_plan)

      expect(described_class.list).to eq([pro_plan])
    end
  end

  describe '.retrieve' do
    it 'retrieves a plan from Stripe' do
      stripe_plan = double('stripe_plan')
      allow(Stripe::Plan).to receive(:retrieve).with('test_pro').
        and_return(stripe_plan)
      allow(described_class).to receive(:add_stripe_namespace).with('pro').
        and_return('test_pro')

      plan = described_class.retrieve('pro')
      expect(plan).to be_an_instance_of(described_class)
    end

    it 'returns nil if Stripe::InvalidRequestError is raised' do
      allow(Stripe::Plan).to receive(:retrieve).
        and_raise(Stripe::InvalidRequestError.new('', ''))

      expect(described_class.retrieve('invalid')).to be_nil
    end
  end

  describe '#to_param' do
    it 'removes the stripe namespace from the id' do
      plan = described_class.new(double('stripe_plan', id: 'test_pro'))
      allow(plan).to receive(:remove_stripe_namespace).with('test_pro').
        and_return('pro')

      expect(plan.to_param).to eq('pro')
    end
  end

  describe '#product' do
    let(:stripe_plan) { double('stripe_plan', product: 'prod_123') }
    let(:plan) { described_class.new(stripe_plan) }

    it 'retrieves the product from Stripe' do
      product = double('product')
      allow(Stripe::Product).to receive(:retrieve).with('prod_123').
        and_return(product)

      expect(plan.product).to eq(product)
    end

    it 'memoizes the result' do
      expect(Stripe::Product).to receive(:retrieve).once.
        and_return(double('product'))
      2.times { plan.product }
    end

    it 'returns nil if there is no product_id' do
      allow(stripe_plan).to receive(:product).and_return(nil)

      expect(plan.product).to be_nil
    end
  end

  describe '#amount_with_tax' do
    context 'with the default tax rate' do
      it 'adds 20% tax to the plan amount' do
        expect(subject.amount_with_tax).to eq(1000)
      end
    end

    context 'with a custom tax rate' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:stripe_tax_rate).and_return('0.25')
      end

      it 'adds 25% tax to the plan amount' do
        expect(subject.amount_with_tax).to eq(1041)
      end
    end
  end

  it 'delegates to the stripe plan' do
    expect(subject.amount).to eq(833)
  end
end
