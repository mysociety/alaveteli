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
            PublicBodyCategories.add(:en, [
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

    context "requesting data" do

        it 'should call load_categories if categories are not already loaded' do
            PublicBodyCategory.stub!(:count).and_return(0)
            PublicBodyCategory.should_receive(:load_categories)
            PublicBodyCategory::get()
        end

    end
end
