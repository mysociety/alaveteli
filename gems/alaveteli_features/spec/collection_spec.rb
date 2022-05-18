require 'spec_helper'
require 'alaveteli_features/collection'
require_relative 'mocks/collection_object'

RSpec.describe AlaveteliFeatures::Collection do
  let(:collection) { described_class.new(MockCollectionObject) }

  describe '#klass' do
    it 'requires argument when initializing' do
      expect(collection.klass).to eq(MockCollectionObject)
    end
  end

  describe '#add' do
    subject(:instance) { collection.add(:test_feature) }

    it 'builds and return klass instance' do
      is_expected.to be_a(MockCollectionObject)
      expect(instance.key).to eq(:test_feature)
    end
  end

  describe '#all' do
    subject { collection.all }

    it 'returns array' do
      is_expected.to be_an(Array)
    end

    it 'includes added instances' do
      instance = collection.add(:test_feature)
      is_expected.to include(instance)
    end
  end
end
