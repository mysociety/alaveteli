# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe PublicBodyCategory::CategoryCollection do
  context "requesting data" do

    before do
      data = [ "Local and regional",
               [ "local_council", "Local councils", "a local council" ],
               "Miscellaneous",
               [ "other", "Miscellaneous", "miscellaneous" ] ]
      @categories = PublicBodyCategory::CategoryCollection.new
      data.each { |item| @categories << item }
    end

    describe 'when asked for headings' do

      it 'should return a list of headings' do
        expect(@categories.headings).to eq(['Local and regional', 'Miscellaneous'])
      end

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
        expect(@categories.with_headings).to eq(expected_categories)
      end
    end



    describe 'when asked for tags by headings' do
      it 'should return a hash of tags keyed by heading' do
        expect(@categories.by_heading).to eq({'Local and regional' => ['local_council'],
                                          'Miscellaneous' => ['other']})
      end
    end

    describe 'when asked for categories with description' do
      it 'should return a list of tag specifications as lists in the form:
                ["tag_to_use_as_category", "Sub category title", "Instance description"]' do
        expected_categories = [
          ["local_council", "Local councils", "a local council"],
          ["other", "Miscellaneous", "miscellaneous"]
        ]
        expect(@categories.with_description).to eq(expected_categories)
      end
    end

    describe 'when asked for tags' do
      it 'should return a list of tags' do
        expect(@categories.tags).to eq(["local_council", "other"])
      end
    end

    describe 'when asked for categories by tag' do
      it 'should return a hash of categories keyed by tag' do
        expect(@categories.by_tag).to eq({
          "local_council" => "Local councils",
          "other" => "Miscellaneous"
        })
      end
    end

    describe 'when asked for singular_by_tag' do
      it 'should return a hash of category descriptions keyed by tag' do
        expect(@categories.singular_by_tag).to eq({
          "local_council" => "a local council",
          "other" => "miscellaneous"
        })
      end
    end
  end
end
