# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutgoingMailer, " when working out follow up names and addresses" do

    before do
        @info_request = mock_model(InfoRequest,
                                    :recipient_name_and_email => 'test <test@example.com>',
                                    :recipient_email => 'test@example.com')
        @info_request.stub_chain(:public_body, :name).and_return("Test Authority")
        @incoming_message = mock_model(IncomingMessage,
                                        :from_email => 'specific@example.com',
                                        :safe_mail_from => 'Specific Person')
    end

    def expect_address(info_request, incoming_message, expected_result)
        mail = create_message_from(from_line)
        name = MailHandler.get_from_name(mail)
        email = MailHandler.get_from_address(mail)
        address = MailHandler.address_from_name_and_email(name, email).to_s
        [name, email, address].should == expected_result
    end

    describe 'if there is no incoming message being replied to' do

        it 'should return the name and email address of the public body' do
            OutgoingMailer.name_and_email_for_followup(@info_request, nil).should == 'test <test@example.com>'
            OutgoingMailer.name_for_followup(@info_request, nil).should == 'Test Authority'
            OutgoingMailer.email_for_followup(@info_request, nil).should == 'test@example.com'
        end

    end

    describe 'if the incoming message being replied to is not valid to reply to' do

        before do
            @incoming_message.stub!(:valid_to_reply_to?).and_return(false)
        end

        it 'should return the safe name and email address of the public body' do
            OutgoingMailer.name_and_email_for_followup(@info_request, @incoming_message).should == 'test <test@example.com>'
            OutgoingMailer.name_for_followup(@info_request, @incoming_message).should == 'Test Authority'
            OutgoingMailer.email_for_followup(@info_request, @incoming_message).should == 'test@example.com'
        end
    end

    describe 'if the incoming message is valid to reply to' do

        before do
            @incoming_message.stub!(:valid_to_reply_to?).and_return(true)
        end

        it 'should return the name and email address from the incoming message' do
            OutgoingMailer.name_and_email_for_followup(@info_request, @incoming_message).should == 'Specific Person <specific@example.com>'
            OutgoingMailer.name_for_followup(@info_request, @incoming_message).should == 'Specific Person'
            OutgoingMailer.email_for_followup(@info_request, @incoming_message).should == 'specific@example.com'
        end

        it 'should return the name of the public body if the incoming message does not have
            a safe name' do
            @incoming_message.stub!(:safe_mail_from).and_return(nil)
            OutgoingMailer.name_for_followup(@info_request, @incoming_message).should == 'Test Authority'
        end

    end

end

describe OutgoingMailer, "when working out follow up subjects" do

    before(:each) do
        load_raw_emails_data
    end

    it "should prefix the title with 'Freedom of Information request -' for initial requests" do
        ir = info_requests(:fancy_dog_request)
        im = ir.incoming_messages[0]

        ir.email_subject_request(:html => false).should == "Freedom of Information request - Why do you have & such a fancy dog?"
    end

    it "should use 'Re:' and inital request subject for followups which aren't replies to particular messages" do
        ir = info_requests(:fancy_dog_request)
        om = outgoing_messages(:useless_outgoing_message)

        OutgoingMailer.subject_for_followup(ir, om, :html => false).should == "Re: Freedom of Information request - Why do you have & such a fancy dog?"
    end

    it "should prefix with Re: the subject of the message being replied to" do
        ir = info_requests(:fancy_dog_request)
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        OutgoingMailer.subject_for_followup(ir, om, :html => false).should == "Re: Geraldine FOI Code AZXB421"
    end

    it "should not add Re: prefix if there already is such a prefix" do
        ir = info_requests(:fancy_dog_request)
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: Re: Geraldine FOI Code AZXB421")
        OutgoingMailer.subject_for_followup(ir, om, :html => false).should == "Re: Geraldine FOI Code AZXB421"
    end

    it "should not add Re: prefix if there already is a lower case re: prefix" do
        ir = info_requests(:fancy_dog_request)
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: re: Geraldine FOI Code AZXB421")
        im.parse_raw_email! true

        OutgoingMailer.subject_for_followup(ir, om, :html => false).should == "re: Geraldine FOI Code AZXB421"
    end

    it "should use 'Re:' and initial request subject when replying to failed delivery notifications" do
        ir = info_requests(:fancy_dog_request)
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        im.raw_email.data = im.raw_email.data.sub("foiperson@localhost", "postmaster@localhost")
        im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: Delivery Failed")
        im.parse_raw_email! true

        OutgoingMailer.subject_for_followup(ir, om, :html => false).should == "Re: Freedom of Information request - Why do you have & such a fancy dog?"
    end
end


