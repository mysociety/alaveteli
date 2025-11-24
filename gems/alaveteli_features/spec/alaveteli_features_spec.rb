require 'spec_helper'
require 'flipper/adapters/memory'

RSpec.describe AlaveteliFeatures do
  it 'should have a version number' do
    expect(AlaveteliFeatures::VERSION).not_to be_nil
  end

  describe '.features' do
    it 'returns a Collection' do
      expect(AlaveteliFeatures.features).to be_a(AlaveteliFeatures::Collection)
    end

    it 'returns a collection which creates Feature instances' do
      expect(AlaveteliFeatures.features.add(:test_feature)).to be_a(
        AlaveteliFeatures::Feature
      )
    end
  end

  describe '.groups' do
    it 'returns a Collection' do
      expect(AlaveteliFeatures.groups).to be_a(AlaveteliFeatures::Collection)
    end

    it 'returns a collection which created Group instances' do
      expect(AlaveteliFeatures.groups.add(:test_feature)).to be_a(
        AlaveteliFeatures::Group
      )
    end
  end

  describe '.backend' do
    it 'should allow you to access the backend' do
      expect(AlaveteliFeatures.backend).not_to be_nil
    end

    it 'should allow you to set the backend' do
      test_backend = Flipper.new(Flipper::Adapters::Memory.new)
      old_backend = AlaveteliFeatures.backend
      AlaveteliFeatures.backend = test_backend
      expect(AlaveteliFeatures.backend).to be test_backend
      AlaveteliFeatures.backend = old_backend
    end
  end
end
