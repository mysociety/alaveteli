require File.dirname(__FILE__) + '/../spec_helper'

describe CensorRule, "substituting things" do 
    before do
        @censor_rule = CensorRule.new
        @censor_rule.text = "goodbye"
        @censor_rule.replacement = "hello"
    end

    it 'should do basic text substitution' do 
        body = "I don't know why you say goodbye"
        @censor_rule.apply_to_text!(body)
        body.should == "I don't know why you say hello"
    end

    it 'should keep size same for binary substitution' do 
        body = "I don't know why you say goodbye"
        orig_body = body.dup
        @censor_rule.apply_to_binary!(body)
        body.size.should == orig_body.size
        body.should == "I don't know why you say xxxxxxx"
        body.should_not == orig_body # be sure duplicated as expected
    end
end
 
