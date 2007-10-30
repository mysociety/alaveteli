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

end


