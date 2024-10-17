require 'spec_helper'

describe AlaveteliPro::PlanHelper do
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
end
