require 'spec_helper'
require 'alaveteli_features/feature'

RSpec.describe AlaveteliFeatures::Feature do
  let(:instance) { described_class.new(key: :feature) }

  describe '#key' do
    it 'requires argument when initializing' do
      expect(instance.key).to eq(:feature)
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe '#label' do
    it 'default to #key when initializing' do
      expect(instance.label).to eq(:feature)
    end

    it 'takes optional argument when initializing' do
      instance = described_class.new(key: :feature, label: 'Label')
      expect(instance.label).to eq('Label')
    end
  end

  describe '#to_sym' do
    subject { instance.to_sym }
    it { is_expected.to eq(:feature) }
  end
end
