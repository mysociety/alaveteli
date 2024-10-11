require 'spec_helper'

describe AlaveteliPro::PriceHelper do
  let(:price) { double('Stripe::Price') }

  describe '#billing_frequency' do
    it 'returns "Billed: Daily" for daily price' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'day', 'interval_count' => 1)
      expect(helper.billing_frequency(price)).to eq('Billed: Daily')
    end

    it 'returns "Billed: Weekly" for weekly price' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'week', 'interval_count' => 1)
      expect(helper.billing_frequency(price)).to eq('Billed: Weekly')
    end

    it 'returns "Billed: Monthly" for monthly price' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'month', 'interval_count' => 1)
      expect(helper.billing_frequency(price)).to eq('Billed: Monthly')
    end

    it 'returns "Billed: Annually" for yearly price' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'year', 'interval_count' => 1)
      expect(helper.billing_frequency(price)).to eq('Billed: Annually')
    end

    it 'returns custom message for other intervals' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'quarter', 'interval_count' => 1)
      expect(helper.billing_frequency(price)).to eq('Billed: every quarter')
    end

    it 'returns custom message for intervals with count greater then 1' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'week', 'interval_count' => 2)
      expect(helper.billing_frequency(price)).to eq('Billed: every 2 weeks')
    end
  end

  describe '#billing_interval' do
    it 'returns singular interval for interval_count of 1' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'month', 'interval_count' => 1)
      expect(helper.billing_interval(price)).to eq('per user, per month')
    end

    it 'returns plural interval for interval_count greater than 1' do
      allow(price).to receive(:recurring).
        and_return('interval' => 'month', 'interval_count' => 3)
      expect(helper.billing_interval(price)).to eq('per user, every 3 months')
    end
  end
end
