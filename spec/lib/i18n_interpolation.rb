require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when using i18n" do

    it "should not complain if we're missing variables from the string" do
        result = _('Hello', :dip => 'hummus')
        result.should == 'Hello'
        result = _('Hello {{dip}}', :dip => 'hummus')
        result.should == 'Hello hummus'
    end
end

