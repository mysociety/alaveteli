require 'spec_helper'

RSpec.describe Dataset::Key, type: :model do
  subject(:key) { FactoryBot.build(:dataset_key) }

  describe 'associations' do
    subject(:key) do
      FactoryBot.create(:dataset_key, value_count: 2)
    end

    it 'belongs to a key set' do
      expect(key.key_set).to be_a Dataset::KeySet
    end

    it 'has many values' do
      expect(key.values).to all be_a(Dataset::Value)
      expect(key.values.count).to eq 2
    end
  end

  describe 'default scope' do
    it 'orders instances by the ascending order value' do
      instance_2 = FactoryBot.create(:dataset_key, order: 2)
      instance_1 = FactoryBot.create(:dataset_key, order: 1)
      expect(Dataset::Key.all).to eq([instance_1, instance_2])
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires title' do
      key.title = nil
      is_expected.not_to be_valid
    end

    it 'requires format' do
      key.format = nil
      is_expected.not_to be_valid
    end

    it 'requires order' do
      key.order = nil
      is_expected.not_to be_valid
    end

    it 'requires known format' do
      key.format = 'other'
      is_expected.not_to be_valid
      key.format = 'text'
      is_expected.to be_valid
      key.format = 'numeric'
      is_expected.to be_valid
      key.format = 'boolean'
      is_expected.to be_valid
    end

    it 'scopes order to key set' do
      other_key = FactoryBot.create(:dataset_key)

      key.key_set = other_key.key_set
      key.order = other_key.order
      is_expected.not_to be_valid

      key.key_set = other_key.key_set
      key.order = other_key.order + 1
      is_expected.to be_valid

      key.key_set = FactoryBot.build(:dataset_key_set)
      key.order = other_key.order
      is_expected.to be_valid
    end
  end

  describe '#format_regexp' do
    subject { key.format_regexp }

    context 'text format' do
      let(:key) { FactoryBot.build(:dataset_key, :text) }
      it { is_expected.to eq described_class::FORMATS[:text] }
    end

    context 'numeric format' do
      let(:key) { FactoryBot.build(:dataset_key, :numeric) }
      it { is_expected.to eq described_class::FORMATS[:numeric] }
    end

    context 'boolean format' do
      let(:key) { FactoryBot.build(:dataset_key, :boolean) }
      it { is_expected.to eq described_class::FORMATS[:boolean] }
    end
  end
end
