# This is a test of the set_content_type monkey patch in
# lib/tmail_extensions.rb

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "when using TMail" do

    it "should load an email with funny MIME settings" do
        # just send it to the holding pen
        InfoRequest.holding_pen_request.incoming_messages.size.should == 0
        receive_incoming_mail("humberside-police-odd-mime-type.email", 'dummy')
        InfoRequest.holding_pen_request.incoming_messages.size.should == 1

        # clear the notification of new message in holding pen
        deliveries = ActionMailer::Base.deliveries
        deliveries.size.should == 1
        deliveries.clear

        incoming_message = InfoRequest.holding_pen_request.incoming_messages[0]

        # This will raise an error if the bug in TMail hasn't been fixed
        incoming_message.get_body_for_html_display()
    end

    it 'should parse multiple to addresses with unqoted display names' do
        example_file = File.join(Spec::Runner.configuration.fixture_path, 'multiple-unquoted-display-names.email')
        mail = TMail::Mail.parse(File.read(example_file))
        mail.to.should == ["request-66666-caa77777@whatdotheyknow.com", "foi@example.com"]
    end

end

