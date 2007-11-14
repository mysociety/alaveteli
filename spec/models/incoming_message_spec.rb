require File.dirname(__FILE__) + '/../spec_helper'

describe IncomingMessage, " when dealing with incoming mail" do
    fixtures :incoming_messages

    before do
        @im = incoming_messages(:useless_incoming_message)
    end

    it "should return the mail Date header date for sent at" do
        @im.sent_at.should == @im.mail.date
    end

end


