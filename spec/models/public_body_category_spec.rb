# == Schema Information
#
# Table name: public_body_categories
#
#  id           :integer          not null, primary key
#  category_tag :text             not null
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PublicBodyCategory do

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
    end
end
