# == Schema Information
#
# Table name: public_body_categories
#
#  id            :integer        not null, primary key
#  locale        :string
#  title         :text           not null
#  category_tag  :text           not null
#  description   :text           not null
#  display_order :integer
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
    end

    it 'should delete the links to category headings when deleted' do
        heading = FactoryGirl.create(:public_body_heading)
        category = FactoryGirl.create(:public_body_category)
        category.add_to_heading(heading)

        link = category.public_body_category_links.first
        link.should_not be_nil

        category.destroy()

        expect { link.reload() }.to raise_error(ActiveRecord::RecordNotFound)
    end

end
