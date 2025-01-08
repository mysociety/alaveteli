# == Schema Information
# Schema version: 20240926164308
#
# Table name: dataset_keys
#
#  id                 :bigint           not null, primary key
#  dataset_key_set_id :bigint
#  title              :string
#  format             :string
#  order              :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  options            :jsonb
#

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
      key.format = 'select'
      is_expected.to be_valid
      key.format = 'numeric'
      is_expected.to be_valid
      key.format = 'boolean'
      is_expected.to be_valid
    end
  end

  describe '.format_options' do
    subject { described_class.format_options }

    it 'returns title/format key hash' do
      is_expected.to eq(
        { 'Text' => :text, 'Select' => :select, 'Numeric' => :numeric,
          'Yes/No' => :boolean }
      )
    end
  end

  describe '#format_regexp' do
    subject { key.format_regexp }

    context 'text format' do
      let(:key) { FactoryBot.build(:dataset_key, :text) }
      it { is_expected.to eq described_class::FORMATS[:text][:regexp] }
    end

    context 'select format' do
      let(:key) { FactoryBot.build(:dataset_key, :select) }
      it { is_expected.to eq described_class::FORMATS[:select][:regexp] }
    end

    context 'numeric format' do
      let(:key) { FactoryBot.build(:dataset_key, :numeric) }
      it { is_expected.to eq described_class::FORMATS[:numeric][:regexp] }
    end

    context 'boolean format' do
      let(:key) { FactoryBot.build(:dataset_key, :boolean) }
      it { is_expected.to eq described_class::FORMATS[:boolean][:regexp] }
    end
  end
end
