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

    it 'should produce the expected text for an internal review request' do
        public_body = mock_model(PublicBody, :name => 'A test public body')
        info_request = mock_model(InfoRequest, :public_body => public_body,
                                               :url_title => 'a_test_title',
                                               :title => 'A test title',
                                               :apply_censor_rules_to_text! => nil)
        outgoing_message = OutgoingMessage.new({
            :status => 'ready',
            :message_type => 'followup',
            :what_doing => 'internal_review',
            :info_request => info_request
        })
        expected_text = "I am writing to request an internal review of A test public body's handling of my FOI request 'A test title'."
        outgoing_message.body.should include(expected_text)
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


