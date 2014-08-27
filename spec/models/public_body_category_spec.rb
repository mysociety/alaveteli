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
                    category_display_order.should eq 1

            cat_group2[1].title.should eq "Aardvark"
            cat_group2[1].public_body_category_links.where(
                :public_body_heading_id => headings[1].id).
                    first.
                    category_display_order.should eq 2
        end
    end

    context "requesting data" do
        before do
            load_test_categories
        end

        describe 'when asked for categories with headings' do
            it 'should return a list of headings as plain strings, each followed by n tag specifications as
                lists in the form:
                ["tag_to_use_as_category", "Sub category title", "Instance description"]' do
                expected_categories = ["Local and regional", ["local_council",
                                                              "Local councils",
                                                              "a local council"],
                                       "Miscellaneous", ["other",
                                                         "Miscellaneous",
                                                         "miscellaneous"]]
                PublicBodyCategory::get().with_headings().should == expected_categories
            end
        end

        describe 'when asked for headings' do
            it 'should return a list of headings' do
                PublicBodyCategory::get().headings().should == ['Local and regional', 'Miscellaneous']
            end

            it 'should call load_categories if categories are not already loaded' do
                PublicBodyCategory.stub!(:count).and_return(0)
                PublicBodyCategory.should_receive(:load_categories)
                PublicBodyCategory::get()
            end
        end

        describe 'when asked for tags by headings' do
            it 'should return a hash of tags keyed by heading' do
                PublicBodyCategory::get().by_heading().should == {'Local and regional' => ['local_council'],
                                                                    'Miscellaneous' => ['other']}
            end
        end

        describe 'when asked for categories with description' do
            it 'should return a list of tag specifications as lists in the form:
                ["tag_to_use_as_category", "Sub category title", "Instance description"]' do
                expected_categories = [
                                            ["local_council", "Local councils", "a local council"],
                                            ["other", "Miscellaneous", "miscellaneous"]
                                      ]
                PublicBodyCategory::get().with_description().should == expected_categories
            end
        end

        describe 'when asked for tags' do
            it 'should return a list of tags' do
                PublicBodyCategory::get().tags().should == ["local_council", "other"]
            end
        end

        describe 'when asked for categories by tag' do
            it 'should return a hash of categories keyed by tag' do
                PublicBodyCategory::get().by_tag().should == {
                    "local_council" => "Local councils",
                    "other" => "Miscellaneous"
                }
            end
        end

        describe 'when asked for singular_by_tag' do
            it 'should return a hash of category descriptions keyed by tag' do
                PublicBodyCategory::get().singular_by_tag().should == {
                    "local_council" => "a local council",
                    "other" => "miscellaneous"
                }
            end
        end
    end
end