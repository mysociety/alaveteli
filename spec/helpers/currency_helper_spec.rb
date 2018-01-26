require 'spec_helper'

describe CurrencyHelper do
  include CurrencyHelper

  describe '#format_currency' do

    it 'format amount in the configured currency' do
      allow(AlaveteliConfiguration).to receive(:iso_currency_code).
        and_return('GBP')
      expect(format_currency(123456)).to eq('£1,234.56')

      allow(AlaveteliConfiguration).to receive(:iso_currency_code).
        and_return('HRK')
      expect(format_currency(123456)).to eq('1.234,56 kn')
    end

  end

end
