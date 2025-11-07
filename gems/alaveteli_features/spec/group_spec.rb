require 'spec_helper'
require 'alaveteli_features/group'
require_relative 'mocks/role'

RSpec.describe AlaveteliFeatures::Group do
  let(:instance) { described_class.new(key: :group, features: [feature]) }
  let(:feature) { AlaveteliFeatures::Feature.new(key: :feature) }

  let(:other_group) do
    described_class.new(key: :other_group, features: [other_feature])
  end
  let(:other_feature) { AlaveteliFeatures::Feature.new(key: :other_feature) }

  describe '#key' do
    it 'requires argument when initializing' do
      instance = described_class.new(key: :group)
      expect(instance.key).to eq(:group)
      expect { described_class.new }.to raise_error(ArgumentError)
    end
  end

  describe '#includes' do
    it 'default to empty array when initializing' do
      instance = described_class.new(key: :group)
      expect(instance.includes).to eq([])
    end

    it 'takes optional argument when initializing' do
      instance = described_class.new(key: :group, includes: [other_group])
      expect(instance.includes).to include(other_group)
    end
  end

  describe '#roles' do
    let(:role) { MockRole.new(:admin) }

    it 'default to empty array when initializing' do
      instance = described_class.new(key: :group)
      expect(instance.roles).to eq([])
    end

    it 'takes optional argument when initializing' do
      instance = described_class.new(key: :group, roles: [role])
      expect(instance.roles).to include(role)
    end

    it 'updates features with roles' do
      expect do
        described_class.new(
          key: :group, features: [feature], roles: [role]
        )
      end.to change(feature, :roles).from([]).to([role])
    end
  end

  describe '#to_sym' do
    subject { instance.to_sym }
    it { is_expected.to eq(:group) }
  end

  describe '#features' do
    subject { instance.features }

    let(:instance) do
      described_class.new(
        key: :group, features: [feature], includes: [other_group]
      )
    end

    it 'returns features passed in from initializer' do
      is_expected.to include(feature)
    end

    it 'returns features from other included groups' do
      is_expected.to include(other_feature)
    end
  end
end
