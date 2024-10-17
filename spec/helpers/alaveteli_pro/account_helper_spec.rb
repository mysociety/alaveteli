require 'spec_helper'

describe AlaveteliPro::AccountHelper do
  describe '#billing_frequency' do
    it 'returns correct billing frequency for day' do
      expect(helper.billing_frequency('day')).to eq('Billed: Daily')
    end

    it 'returns correct billing frequency for week' do
      expect(helper.billing_frequency('week')).to eq('Billed: Weekly')
    end

    it 'returns correct billing frequency for month' do
      expect(helper.billing_frequency('month')).to eq('Billed: Monthly')
    end

    it 'returns correct billing frequency for year' do
      expect(helper.billing_frequency('year')).to eq('Billed: Annually')
    end
  end

  describe '#card_expiry_message' do
    it 'returns expiry message when card expires this month' do
      allow(Date).to receive(:today).and_return(Date.new(2023, 5, 1))
      expect(helper.card_expiry_message(5, 2023)).to eq('<p class="card__expiring">Expires soon</p>')
    end

    it 'returns nil when card does not expire this month' do
      allow(Date).to receive(:today).and_return(Date.new(2023, 5, 1))
      expect(helper.card_expiry_message(6, 2023)).to be_nil
    end
  end
end
