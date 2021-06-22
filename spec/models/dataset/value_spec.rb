# == Schema Information
# Schema version: 20210114161442
#
# Table name: dataset_values
#
#  id                   :bigint           not null, primary key
#  dataset_value_set_id :bigint
#  dataset_key_id       :bigint
#  value                :string
#  notes                :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

require 'spec_helper'

RSpec.describe Dataset::Value, type: :model do
  subject(:value) { FactoryBot.build(:dataset_value) }

  describe 'associations' do
    it 'belongs to a value set' do
      expect(value.value_set).to be_a Dataset::ValueSet
    end

    it 'belongs to a key' do
      expect(value.key).to be_a Dataset::Key
    end
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it 'requires value set' do
      value.value_set = nil
      is_expected.not_to be_valid
    end

    it 'requires key' do
      value.key = nil
      is_expected.not_to be_valid
    end

    context 'checks format of the value' do
      def valid(value_to_test)
        value.value = value_to_test
        is_expected.to be_valid
      end

      def invalid(value_to_test)
        value.value = value_to_test
        is_expected.to be_invalid
      end

      it 'checks text values' do
        value.key = FactoryBot.build(:dataset_key, :text)
        valid('')
        valid('A string')
        valid("A\nstring")
        valid("A\r\nstring")
        valid('1234')
        valid('1')
        valid('0')
      end

      it 'checks numeric values' do
        value.key = FactoryBot.build(:dataset_key, :numeric)
        valid('')
        invalid('A string')
        valid('1234')
        valid('1')
        valid('0')
      end

      it 'checks boolean values' do
        value.key = FactoryBot.build(:dataset_key, :boolean)
        valid('')
        invalid('A string')
        invalid('1234')
        valid('1')
        valid('0')
      end
    end
  end
end
