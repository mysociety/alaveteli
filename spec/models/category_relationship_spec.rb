# == Schema Information
#
# Table name: category_relationships
#
#  id         :bigint           not null, primary key
#  parent_id  :integer          not null
#  child_id   :integer          not null
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

RSpec.describe CategoryRelationship, type: :model do
  let(:category_relationship) { FactoryBot.build(:category_relationship) }

  describe 'validations' do
    specify { expect(category_relationship).to be_valid }

    it 'sets position to the next whole number' do
      first_relationship = FactoryBot.create(
        :category_relationship, position: 1
      )
      category_relationship.parent = first_relationship.parent
      category_relationship.position = nil
      expect { category_relationship.valid? }.
        to change(category_relationship, :position).to(2)
    end

    it 'does not overwrite existing position' do
      category_relationship.position = 10
      expect { category_relationship.valid? }.
        to_not change(category_relationship, :position)
    end
  end

  describe 'associations' do
    it 'belongs to parent' do
      parent = FactoryBot.create(:category)
      category_relationship = FactoryBot.create(
        :category_relationship, parent: parent
      )
      expect(category_relationship.parent).to eq(parent)
    end

    it 'belongs to child' do
      child = FactoryBot.create(:category)
      category_relationship = FactoryBot.create(
        :category_relationship, child: child
      )
      expect(category_relationship.child).to eq(child)
    end
  end
end
