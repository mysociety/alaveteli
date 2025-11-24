require 'spec_helper'
require 'alaveteli_features/collection'
require_relative 'mocks/collection_object'

RSpec.describe AlaveteliFeatures::Collection do
  let(:collection) { described_class.new(MockCollectionObject) }

  describe '#klass' do
    it 'requires argument when initializing' do
      expect(collection.klass).to eq(MockCollectionObject)
    end

    it 'extends the collection' do
      expect { collection.with_actor('bob') }.to_not raise_error
      expect(collection.with_actor('bob')).to eq(collection)
      expect(collection.actor).to eq('bob')
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

  describe '#each' do
    before { collection.add(:test_feature) }

    it 'loops over all added instances' do
      expect(collection.map(&:key)).to match([:test_feature])
    end
  end
end
