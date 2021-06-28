require 'spec_helper'

describe AlaveteliPro::WithTax do
  let(:plan) { double(:plan, amount: 833) }
  subject { described_class.new(plan) }

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
