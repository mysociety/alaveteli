# == Schema Information
# Schema version: 20210114161442
#
# Table name: dataset_value_sets
#
#  id                 :bigint           not null, primary key
#  resource_type      :string
#  resource_id        :bigint
#  dataset_key_set_id :bigint
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require 'spec_helper'

RSpec.describe Dataset::ValueSet, type: :model do
  subject(:value_set) { FactoryBot.build(:dataset_value_set) }

  describe 'associations' do
    subject(:value_set) do
      FactoryBot.create(:dataset_value_set, value_count: 2)
    end

    context 'when info request value set' do
      let(:value_set) do
        FactoryBot.build(:dataset_value_set, :for_info_request)
      end

      it 'belongs to a info request via polymorphic resource' do
        expect(value_set.resource).to be_a InfoRequest
      end
    end

    context 'when incoming message value set' do
      let(:value_set) do
        FactoryBot.build(:dataset_value_set, :for_incoming_message)
      end

      it 'belongs to a incoming message via polymorphic resource' do
        expect(value_set.resource).to be_a IncomingMessage
      end
    end

    context 'when FOI attachment value set' do
      let(:value_set) do
        FactoryBot.build(:dataset_value_set, :for_foi_attachment)
      end

      it 'belongs to a FOI attachment via polymorphic resource' do
        expect(value_set.resource).to be_a FoiAttachment
      end
    end

    it 'belongs to a key set' do
      expect(value_set.key_set).to be_a Dataset::KeySet
    end

    it 'has many values' do
      expect(value_set.values).to all be_a(Dataset::Value)
      expect(value_set.values.count).to eq 2
    end
  end

  describe 'nested attibutes' do
    it 'accpets attributes for values' do
      key = FactoryBot.create(:dataset_key)
      value_set = FactoryBot.create(
        :dataset_value_set,
        value_count: 0,
        values_attributes: [{ dataset_key_id: key.id, value: '1' }]
      )
      value = value_set.values.first
      expect(value).to be_a Dataset::Value
      expect(value.key).to eq key
      expect(value.value).to eq '1'
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'does not require resource' do
      value_set.resource = nil
      is_expected.to be_valid
    end

    it 'requires resource to be a InfoRequest, IncomingMessage or FoiAttachment' do
      value_set.resource = FactoryBot.build(:user)
      is_expected.not_to be_valid
      value_set.resource = FactoryBot.build(:info_request)
      is_expected.to be_valid
      value_set.resource = FactoryBot.build(:incoming_message)
      is_expected.to be_valid
      value_set.resource = FactoryBot.build(:foi_attachment)
      is_expected.to be_valid
    end

    it 'requires key set' do
      value_set.key_set = nil
      is_expected.not_to be_valid
    end

    it 'requires values' do
      value_set.values = []
      is_expected.not_to be_valid
    end

    it 'requires at least one value to be present' do
      value_set.values.each { |v| v.value = '' }
      is_expected.to_not be_valid
    end
  end
end
