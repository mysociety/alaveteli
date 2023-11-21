# == Schema Information
# Schema version: 20231127110827
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  category_tag :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  title        :string
#  description  :string
#

require 'spec_helper'

RSpec.describe Category, type: :model do
  set_fixture_class has_tag_string_tags: HasTagString::HasTagStringTag

  let(:category) { FactoryBot.build(:category) }

  describe 'validations' do
    specify { expect(category).to be_valid }

    it 'requires title' do
      category.title = nil
      expect(category).not_to be_valid
    end
  end

  describe 'translations' do
    before { category.save! }

    it 'adds translated title' do
      expect(category.title_translations).to_not include(es: 'title')
      AlaveteliLocalization.with_locale(:es) { category.title = 'title' }
      expect(category.title_translations).to include(es: 'title')
    end

    it 'adds translated description' do
      expect(category.description_translations).
        to_not include(es: 'description')

      AlaveteliLocalization.with_locale(:es) do
        category.description = 'description'
      end

      expect(category.description_translations).
        to include(es: 'description')
    end
  end

  describe 'associations' do
    let(:category) { FactoryBot.create(:category, category_tag: '123') }

    it 'has many parents' do
      parent_1 = FactoryBot.create(:category, children: [category])
      parent_2 = FactoryBot.create(:category, children: [category])
      expect(category.parents).to all be_a(Category)
      expect(category.parents).to match_array([parent_1, parent_2])
      expect(category.parent_relationships).to all be_a(CategoryRelationship)
      expect(category.parent_relationships.count).to eq(2)
    end

    it 'has many children' do
      child_1 = FactoryBot.create(:category, parents: [category])
      child_2 = FactoryBot.create(:category, parents: [category])
      expect(category.children).to all be_a(Category)
      expect(category.children).to match_array([child_1, child_2])
      expect(category.child_relationships).to all be_a(CategoryRelationship)
      expect(category.child_relationships.count).to eq(2)
    end

    it 'has many tags' do
      FactoryBot.create(:public_body, tag_string: '123')
      tag = HasTagString::HasTagStringTag.find_by(name: '123')
      expect(category.tags).to all be_a(HasTagString::HasTagStringTag)
      expect(category.tags).to match_array([tag])
    end
  end

  describe '.roots scope' do
    subject { described_class.roots }
    it { is_expected.to include(described_class.public_body_root) }
  end

  describe '.with_parent scope' do
    let(:parent_1) { FactoryBot.create(:category) }
    let(:parent_2) { FactoryBot.create(:category) }

    let(:child) { FactoryBot.create(:category, parents: [parent_1]) }
    let(:child_with_muliple_parents) do
      FactoryBot.create(:category, parents: [parent_1, parent_2])
    end

    let(:other_child) { FactoryBot.create(:category) }

    subject { described_class.with_parent(parent_1) }

    it { is_expected.to include(child) }
    it { is_expected.to include(child_with_muliple_parents) }
    it { is_expected.to_not include(other_child) }
  end

  describe '.public_body_root' do
    subject(:root) { described_class.public_body_root }
    it { is_expected.to be_a(described_class) }
    it { expect(root.title).to eq('PublicBody') }
  end
end
