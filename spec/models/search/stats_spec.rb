require 'spec_helper'

RSpec.describe Search::Stats do
  let(:relation) do
    User.where(name: 'Alice Smith').paginate(page: 1, per_page: 1)
  end

  let!(:user) { FactoryBot.create(:user, name: 'Alice Smith') }

  describe '.measure' do
    subject(:stats) { described_class.measure(relation) }

    it 'loads the relation' do
      expect(stats.relation).to be_loaded
    end

    it 'counts every match rather than the current page' do
      FactoryBot.create(:user, name: 'Alice Smith')
      expect(stats.count).to eq(2)
    end
  end

  describe '#explain' do
    subject { described_class.measure(relation).explain }

    it { is_expected.to include('Execution Time') }

    it 'reports a plan when the query cache is on' do
      User.cache { is_expected.to include('Execution Time') }
    end
  end
end
