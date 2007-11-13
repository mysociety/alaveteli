require File.dirname(__FILE__) + '/../spec_helper'

describe RequestMailer, " when receiving incoming mail" do
    fixtures :info_requests

    before do

    end

    it "should append it to the appropriate request" do
        ir = info_requests(:fancy_dog_request) 
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 1
    end
    
    it "should XXX when the email is not to any information request"
end



