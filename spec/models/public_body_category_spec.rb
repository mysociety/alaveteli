# == Schema Information
#
# Table name: public_body_categories
#
#  id           :integer          not null, primary key
#  category_tag :text             not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyCategory do
    describe 'when loading the data' do
        it 'should use the display_order field to preserve the original data order' do
            PublicBodyCategory.add(:en, [
                "Local and regional",
                    [ "local_council", "Local councils", "a local council" ],
                "Miscellaneous",
                    [ "other", "Miscellaneous", "miscellaneous" ],
                    [ "aardvark", "Aardvark", "daft test"],])

            headings = PublicBodyHeading.all
            cat_group1 = headings[0].public_body_categories
            cat_group1.count.should eq 1
            cat_group1[0].title.should eq "Local councils"

            cat_group2 = headings[1].public_body_categories
            cat_group2.count.should eq 2
            cat_group2[0].title.should eq "Miscellaneous"
            cat_group2[0].public_body_category_links.where(
                :public_body_heading_id => headings[1].id).
                    first.
                    category_display_order.should eq 0

            cat_group2[1].title.should eq "Aardvark"
            cat_group2[1].public_body_category_links.where(
                :public_body_heading_id => headings[1].id).
                    first.
                    category_display_order.should eq 1
        end
    end

    context 'when validating' do

        it 'should require a title' do
            category = PublicBodyCategory.new
            category.should_not be_valid
            category.errors[:title].should == ["Title can't be blank"]
        end

        it 'should require a category tag' do
            category = PublicBodyCategory.new
            category.should_not be_valid
            category.errors[:category_tag].should == ["Tag can't be blank"]
        end

        it 'should require a unique tag' do
            existing = FactoryGirl.create(:public_body_category)
            PublicBodyCategory.new(:email => existing.category_tag).should_not be_valid
        end

        it 'should require a description' do
            category = PublicBodyCategory.new
            category.should_not be_valid
            category.errors[:description].should == ["Description can't be blank"]
        end

        it 'validates the translations' do
            category = FactoryGirl.build(:public_body_category)
            translation = category.translations.build
            expect(category).to_not be_valid
        end

    end
end

describe PublicBodyCategory::Translation do

  it 'requires a title' do
    translation = PublicBodyCategory::Translation.new
    translation.valid?
    expect(translation.errors[:title]).to eq(["Title can't be blank"])
  end

  it 'requires a description' do
    translation = PublicBodyCategory::Translation.new
    translation.valid?
    expect(translation.errors[:description]).to eq(["Description can't be blank"])
  end

end
