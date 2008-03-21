require File.dirname(__FILE__) + '/../spec_helper'

describe InfoRequest, " when emailing" do
    fixtures :info_requests

    before do
        @info_request = info_requests(:fancy_dog_request)
    end

    it "should have a valid incoming email" do
        @info_request.incoming_email.should_not be_nil
    end

    it "should recognise its own incoming email" do
        incoming_email = @info_request.incoming_email
        found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
        found_info_request.should == (@info_request)
    end

    it "should recognise old style request-bounce- addresses" do
        incoming_email = @info_request.magic_email("request-bounce-")
        found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
        found_info_request.should == (@info_request)
    end

    it "should return nil when receiving email for a deleted request" do
        deleted_request_address = InfoRequest.magic_email_for_id("request-", 98765)  
        found_info_request = InfoRequest.find_by_incoming_email(deleted_request_address)
        found_info_request.should be_nil
    end

end


