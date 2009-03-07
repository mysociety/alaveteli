require File.dirname(__FILE__) + '/../spec_helper'

describe OutgoingMessage, " when making an outgoing message" do
    before do
    end

    it "should not show email addresses for outgoing messages, except when mailing" do
        outgoing_message = OutgoingMessage.new({
            :status => 'ready',
            :message_type => 'initial_request',
            :body => 'This request contains a foo@bar.com email address',
            :last_sent_at => Time.now(),
            :what_doing => 'normal_sort'
        })

        # used for index, but also for track emails
        outgoing_message.get_text_for_indexing.should_not include("foo@bar.com")

        # used for normal display on page
        outgoing_message.get_body_for_html_display.should_not include("foo@bar.com")

        # called from the request sending email templates
        outgoing_message.body.should include("foo@bar.com")
    end
end


