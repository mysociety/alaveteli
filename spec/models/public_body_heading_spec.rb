# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer        not null, primary key
#  locale        :string
#  name          :text           not null
#  display_order :integer
#

require 'spec_helper'

describe PublicBodyHeading do
    before do
        load_test_categories
    end

    describe 'when loading the data' do
        it 'should use the display_order field to preserve the original data order' do
            headings = PublicBodyHeading.all
            headings[0].name.should eq 'Local and regional'
            headings[0].display_order.should eq 1
            headings[1].name.should eq 'Miscellaneous'
            headings[1].display_order.should eq 2
        end
    end
end
