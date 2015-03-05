# == Schema Information
#
# Table name: public_body_headings
#
#  id            :integer          not null, primary key
#  display_order :integer
#

require 'spec_helper'

describe PublicBodyHeading do

    context 'when validating' do

        it 'should require a name' do
            heading = PublicBodyHeading.new
            heading.should_not be_valid
            heading.errors[:name].should == ["Name can't be blank"]
        end

        it 'should require a unique name' do
            heading = FactoryGirl.create(:public_body_heading)
            new_heading = PublicBodyHeading.new(:name => heading.name)
            new_heading.should_not be_valid
            new_heading.errors[:name].should == ["Name is already taken"]
        end

        it 'should set a default display order based on the next available display order' do
            heading = PublicBodyHeading.new
            heading.valid?
            heading.display_order.should == PublicBodyHeading.next_display_order
        end
    end

    context 'when setting a display order' do

        it 'should return 0 if there are no public body headings' do
            PublicBodyHeading.next_display_order.should == 0
        end

        it 'should return one more than the highest display order if there are public body headings' do
            heading = FactoryGirl.create(:public_body_heading)
            PublicBodyHeading.next_display_order.should == 1
        end
    end
end
