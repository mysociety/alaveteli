require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutgoingMessage, " when making an outgoing message" do

    before do
        @om = outgoing_messages(:useless_outgoing_message)
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

    it "should link to help page where email address was" do
        @outgoing_message.get_body_for_html_display.should include('<a href="/help/officers#mobiles">')
    end

    it "should include email addresses in outgoing messages" do
        @outgoing_message.body.should include("foo@bar.com")
    end

    it "should work out a salutation" do
        @om.get_salutation.should == "Dear Geraldine Quango,"
    end
end


describe IncomingMessage, " when censoring data" do

    before do
        @om = outgoing_messages(:useless_outgoing_message)

        @censor_rule = CensorRule.new()
        @censor_rule.text = "dog"
        @censor_rule.replacement = "cat"
        @censor_rule.last_edit_editor = "unknown"
        @censor_rule.last_edit_comment = "none"

        @om.info_request.censor_rules << @censor_rule
    end

    it "should apply censor rules to outgoing messages" do
        @om.read_attribute(:body).should match(/fancy dog/)
        @om.body.should match(/fancy cat/)
    end
end


