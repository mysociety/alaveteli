require File.dirname(__FILE__) + '/../spec_helper'

describe PostRedirect, " when constructing" do
    before do
    end

    it "should generate a different token from email token" do
        pr = PostRedirect.new 
        pr.token.should_not == pr.email_token
    end

    it "should generate a different token each time" do
        pr_1 = PostRedirect.new 
        pr_2 = PostRedirect.new 
        pr_1.token.should_not be_nil
        pr_2.token.should_not be_nil
        pr_1.token.should_not == pr_2.token
    end

    it "should generate a different email each time" do
        pr_1 = PostRedirect.new 
        pr_2 = PostRedirect.new 
        pr_1.email_token.should_not be_nil
        pr_2.email_token.should_not be_nil
        pr_1.email_token.should_not == pr_2.email_token
    end

    it "should generate a URL friendly token" do
        pr = PostRedirect.new 
        pr.token.should match(/[a-z][0-9]/);
    end

    it "should generate an email friendly email token" do
        pr = PostRedirect.new 
        pr.email_token.should match(/[a-z][0-9]/);
    end
end

describe PostRedirect, " when accessing values" do
    before do
    end

    it "should convert post parameters into YAML and back successfully" do
        pr = PostRedirect.new 
        example_post_params = { :foo => 'this is stuff', :bar => 83, :humbug => "yikes!!!" }
        pr.post_params = example_post_params
        pr.post_params_yaml.should == example_post_params.to_yaml
        pr.post_params.should == example_post_params
    end

    it "should convert reason parameters into YAML and back successfully" do
        pr = PostRedirect.new 
        example_reason_params = { :foo => 'this is stuff', :bar => 83, :humbug => "yikes!!!" }
        pr.reason_params = example_reason_params
        pr.reason_params_yaml.should == example_reason_params.to_yaml
        pr.reason_params.should == example_reason_params
    end
end

