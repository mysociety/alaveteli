require File.dirname(__FILE__) + '/../spec_helper'

describe RequestMailer, " when receiving incoming mail" do
    fixtures :info_requests, :incoming_messages

    before do

    end

    it "should append it to the appropriate request" do
        ir = info_requests(:fancy_dog_request) 
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 2
    end
    
    it "should bounce email to admin when the email is not to any information request" do
        ir = info_requests(:fancy_dog_request) 
        receive_incoming_mail('incoming-request-plain.email', 'dummy@localhost')
        ir.incoming_messages.size.should == 1

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should  == 1
        mail = deliveries[0]
        mail.to.should == [ MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost') ]
    end
end



