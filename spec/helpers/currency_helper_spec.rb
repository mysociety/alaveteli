require 'spec_helper'

describe CurrencyHelper do
  include CurrencyHelper

  describe '#format_currency' do
    before do
      allow(AlaveteliConfiguration).to receive(:iso_currency_code).
        and_return('GBP')
    end

    it 'formats the amount in the configured currency' do
      expect(format_currency(123456)).to eq('£1,234.56')

      allow(AlaveteliConfiguration).to receive(:iso_currency_code).
        and_return('HRK')
      expect(format_currency(123456)).to eq('1.234,56 kn')
    end

    it 'shows currency sub-units by default' do
      expect(format_currency(1500)).to eq('£15.00')
    end

    context 'when asked to show the amount without trailing zeros' do
      it 'does not show the trailing sub-unit amount when it is 00' do
        expect(format_currency(123400, no_cents_if_whole: true)).to eq('£1,234')
      end

      it 'does not rely on the UK currency format' do
        allow(AlaveteliConfiguration).to receive(:iso_currency_code).
          and_return('EUR')
        expect(format_currency(123400, no_cents_if_whole: true)).to eq('€1.234')
      end

      it 'still shows the sub-unit value if it is a non-zero amount' do
        expect(format_currency(1499, no_cents_if_whole: true)).to eq('£14.99')
      end
    end
  end

end
