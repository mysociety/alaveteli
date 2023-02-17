# == Schema Information
# Schema version: 20210114161442
#
# Table name: public_body_category_links
#
#  public_body_category_id :integer          not null
#  public_body_heading_id  :integer          not null
#  category_display_order  :integer
#  id                      :integer          not null, primary key
#  created_at              :datetime
#  updated_at              :datetime
#

require 'spec_helper'

RSpec.describe PublicBodyHeading, 'when validating' do

  it 'should set a default display order based on the next available display order' do
    heading = FactoryBot.create(:public_body_heading)
    category = FactoryBot.create(:public_body_category)
    category_link = PublicBodyCategoryLink.new(public_body_heading: heading,
                                               public_body_category: category)
    category_link.valid?
    expect(category_link.category_display_order).to eq(PublicBodyCategoryLink.next_display_order(heading))
  end

  it 'should be invalid without a category' do
    category_link = PublicBodyCategoryLink.new
    expect(category_link).not_to be_valid
    expect(category_link.errors[:public_body_category]).to eq(["can't be blank"])
  end

  it 'should be invalid without a heading' do
    category_link = PublicBodyCategoryLink.new
    expect(category_link).not_to be_valid
    expect(category_link.errors[:public_body_heading]).to eq(["can't be blank"])
  end

end

RSpec.describe PublicBodyCategoryLink do
  describe '.for_heading' do
    subject { described_class.for_heading(public_body_heading) }

    let(:public_body_heading) { heading_1 }

    let(:heading_1) { FactoryBot.create(:public_body_heading) }

    let(:link_1) do
      FactoryBot.create(:public_body_category_link,
                        public_body_heading: heading_1,
                        category_display_order: 1)
    end

    let(:link_2) do
      FactoryBot.create(:public_body_category_link,
                        public_body_heading: heading_1,
                        category_display_order: 2)
    end

    before do
      link_1.update!(category_display_order: 2)
      link_2.update!(category_display_order: 1)
    end

    it { is_expected.to match_array([link_2, link_1]) }
  end
end

RSpec.describe PublicBodyCategoryLink, 'when setting a category display order' do

  it 'should return 0 if there are no public body headings' do
    heading = FactoryBot.create(:public_body_heading)
    expect(PublicBodyCategoryLink.next_display_order(heading)).to eq(0)
  end

  it 'should return one more than the highest display order if there are public body headings' do
    heading = FactoryBot.create(:public_body_heading)
    category = FactoryBot.create(:public_body_category)
    category_link = PublicBodyCategoryLink.create(public_body_heading_id: heading.id,
                                                  public_body_category_id: category.id)

    expect(PublicBodyCategoryLink.next_display_order(heading)).to eq(1)
  end

end

RSpec.describe PublicBodyCategoryLink, '.by_display_order' do
  subject { described_class.by_display_order }

  before { PublicBodyCategoryLink.destroy_all }

  let(:heading_1) { FactoryBot.build(:public_body_heading, display_order: 2) }
  let(:heading_2) { FactoryBot.build(:public_body_heading, display_order: 1) }
  let(:cat_1) { FactoryBot.build(:public_body_category, category_tag: 'tag_1') }
  let(:cat_2) { FactoryBot.build(:public_body_category, category_tag: 'tag_2') }

  it 'orders headings and categoies by display orders' do
    link_1 = PublicBodyCategoryLink.create(
      public_body_heading: heading_1, public_body_category: cat_1,
      category_display_order: 1
    )
    link_2 = PublicBodyCategoryLink.create(
      public_body_heading: heading_1, public_body_category: cat_2,
      category_display_order: 2
    )
    link_3 = PublicBodyCategoryLink.create(
      public_body_heading: heading_2, public_body_category: cat_2,
      category_display_order: 1
    )

    FactoryBot.create(:public_body, tag_string: 'tag_1')
    FactoryBot.create(:public_body, tag_string: 'tag_2')

    is_expected.to match_array([link_3, link_1, link_2])
  end

  it 'hides headings and categoies without requestable public bodies' do
    PublicBodyCategoryLink.create(
      public_body_heading: heading_1, public_body_category: cat_1,
      category_display_order: 1
    )

    FactoryBot.create(:public_body, tag_string: 'defunct tag_1')
    FactoryBot.create(:public_body, tag_string: 'not_apply tag_1')
    FactoryBot.create(:blank_email_public_body, tag_string: 'tag_1')

    is_expected.to eq([])
  end
end
