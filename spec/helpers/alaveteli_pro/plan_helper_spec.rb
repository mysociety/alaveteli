require 'spec_helper'

describe AlaveteliPro::PlanHelper do
  let(:plan) { double('Plan') }

  describe '#billing_frequency' do
    it 'returns "Billed: Daily" for daily plan' do
      allow(plan).to receive(:interval).and_return('day')
      allow(plan).to receive(:interval_count).and_return(1)
      expect(helper.billing_frequency(plan)).to eq('Billed: Daily')
    end

    it 'returns "Billed: Weekly" for weekly plan' do
      allow(plan).to receive(:interval).and_return('week')
      allow(plan).to receive(:interval_count).and_return(1)
      expect(helper.billing_frequency(plan)).to eq('Billed: Weekly')
    end

    it 'returns "Billed: Monthly" for monthly plan' do
      allow(plan).to receive(:interval).and_return('month')
      allow(plan).to receive(:interval_count).and_return(1)
      expect(helper.billing_frequency(plan)).to eq('Billed: Monthly')
    end

    it 'returns "Billed: Annually" for yearly plan' do
      allow(plan).to receive(:interval).and_return('year')
      allow(plan).to receive(:interval_count).and_return(1)
      expect(helper.billing_frequency(plan)).to eq('Billed: Annually')
    end

    it 'returns custom message for other intervals' do
      allow(plan).to receive(:interval).and_return('quarter')
      allow(plan).to receive(:interval_count).and_return(1)
      expect(helper.billing_frequency(plan)).to eq('Billed: every quarter')
    end

    it 'returns custom message for intervals with count greater then 1' do
      allow(plan).to receive(:interval).and_return('week')
      allow(plan).to receive(:interval_count).and_return(2)
      expect(helper.billing_frequency(plan)).to eq('Billed: every 2 weeks')
    end
  end

  describe '#billing_interval' do
    it 'returns singular interval for interval_count of 1' do
      allow(plan).to receive(:interval).and_return('month')
      allow(plan).to receive(:interval_count).and_return(1)
      expect(helper.billing_interval(plan)).to eq('per user, per month')
    end

    it 'returns plural interval for interval_count greater than 1' do
      allow(plan).to receive(:interval).and_return('month')
      allow(plan).to receive(:interval_count).and_return(3)
      expect(helper.billing_interval(plan)).to eq('per user, every 3 months')
    end
  end
end
