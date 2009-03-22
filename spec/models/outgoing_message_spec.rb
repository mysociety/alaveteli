require File.dirname(__FILE__) + '/../spec_helper'

describe OutgoingMessage, " when making an outgoing message" do
    before do
        @outgoing_message = OutgoingMessage.new({
            :status => 'ready',
            :message_type => 'initial_request',
            :body => 'This request contains a foo@bar.com email address',
            :last_sent_at => Time.now(),
            :what_doing => 'normal_sort'
        })
    end

    it "should not index the email addresses" do
        # also used for track emails
        @outgoing_message.get_text_for_indexing.should_not include("foo@bar.com")
    end 

    it "should not display email addresses on page" do
        @outgoing_message.get_body_for_html_display.should_not include("foo@bar.com")
    end

    it "should include email addresses in outgoing messages" do
        @outgoing_message.body.should include("foo@bar.com")
    end
end


