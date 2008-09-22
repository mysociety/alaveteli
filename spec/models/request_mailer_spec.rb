require File.dirname(__FILE__) + '/../spec_helper'

describe RequestMailer, " when receiving incoming mail" do
    fixtures :info_requests, :incoming_messages, :raw_emails, :users, :public_bodies

    before do

    end

    it "should append it to the appropriate request" do
        ir = info_requests(:fancy_dog_request) 
        ir.incoming_messages.size.should == 1 # in the fixture
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 2 # one more arrives
        ir.info_request_events[-1].incoming_message_id.should_not be_nil

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        deliveries.clear
    end
    
    it "should store mail in holding pen and send to admin when the email is not to any information request" do
        ir = info_requests(:fancy_dog_request) 
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail('incoming-request-plain.email', 'dummy@localhost')
        ir.incoming_messages.size.should == 1
        InfoRequest.holding_pen_request.incoming_messages.size.should == 1

        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost') ]
        deliveries.clear
    end

    it "should return incoming mail to sender when a request is stopped for spam" do
        # mark request as anti-spam
        ir = info_requests(:fancy_dog_request) 
        ir.stop_new_responses = true
        ir.save!

        # test what happens if something arrives
        ir.incoming_messages.size.should == 1 # in the fixture
        receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
        ir.incoming_messages.size.should == 1 # nothing should arrive

        # should be a message back to sender
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        mail = deliveries[0]
        mail.to.should == [ 'geraldinequango@localhost' ]
        deliveries.clear
    end


    it "should not mutilate long URLs when trying to word wrap them" do
        long_url = 'http://www.this.is.quite.a.long.url.flourish.org/there.is.no.way.it.is.short.whatsoever'
        body = "This is a message with quite a long URL in it. It also has a paragraph, being this one that has quite a lot of text in it to. Enough to test the wrapping of itself.

#{long_url}

And a paragraph afterwards."
        wrapped = MySociety::Format.wrap_email_body(body)
        wrapped.should include(long_url)
    end
end



