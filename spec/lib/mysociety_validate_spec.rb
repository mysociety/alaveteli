# This is tests for the code in commonlib/rblib/validate.rb
# XXX move the tests into commonlib

require File.dirname(__FILE__) + '/../spec_helper'

describe "when checking text uses mixed capitals" do

    it "should detect all caps" do
        MySociety::Validate.uses_mixed_capitals("I LIKE TO SHOUT, IT IS FUN. I ESPECIALLY LIKE TO DO SO FOR QUITE A LONG TIME, AND WHEN I DISABLED MY CAPS LOCK KEY.").should == false
    end

    it "should not allow e e cummings" do
        MySociety::Validate.uses_mixed_capitals("
            (i who have died am alive again today,
            and this is the sun's birthday;this is the birth
            day of life and love and wings:and of the gay
            great happening illimitably earth)
        ").should == false
    end

    it "should allow a few normal sentences" do
        MySociety::Validate.uses_mixed_capitals("This is a normal sentence. It is followed by another, and overall it is quite a long chunk of text so it exceeds the minimum limit.").should == true
    end

end

