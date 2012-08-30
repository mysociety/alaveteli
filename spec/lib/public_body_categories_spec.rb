require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyCategories do

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
            PublicBodyCategories::get().with_headings().should == expected_categories
        end

    end

    describe 'when asked for headings' do

        it 'should return a list of headings' do
            PublicBodyCategories::get().headings().should == ['Local and regional', 'Miscellaneous']
        end

    end

    describe 'when asked for tags by headings' do

        it 'should return a hash of tags keyed by heading' do
            PublicBodyCategories::get().by_heading().should == {'Local and regional' => ['local_council'],
                                                                'Miscellaneous' => ['other']}
        end

    end

end