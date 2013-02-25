require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutgoingMailer, " when working out follow up addresses" do
    # This is done with fixtures as the code is a bit tangled with the way it
    # calls TMail.  XXX untangle it and make these tests spread out and using
    # mocks. Put parts of the tests in spec/lib/tmail_extensions.rb
    before(:each) do
        load_raw_emails_data
    end

    it "should parse them right" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "FOI Person <foiperson@localhost>"
        OutgoingMailer.name_for_followup(ir, im).should == "FOI Person"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

    it "should work when there is only an email address" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        im.raw_email.data = im.raw_email.data.sub("\"FOI Person\" <foiperson@localhost>", "foiperson@localhost")
        im.parse_raw_email! true

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "foiperson@localhost"
        OutgoingMailer.name_for_followup(ir, im).should == "Geraldine Quango"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

    it "should quote funny characters" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        im.raw_email.data = im.raw_email.data.sub("FOI Person", "FOI [ Person")
        im.parse_raw_email! true

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "\"FOI [ Person\" <foiperson@localhost>"
        OutgoingMailer.name_for_followup(ir, im).should == "FOI [ Person"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

    it "should quote quotes" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        im.raw_email.data = im.raw_email.data.sub("FOI Person", "FOI \\\" Person")
        im.parse_raw_email! true

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "\"FOI \\\" Person\" <foiperson@localhost>"
        OutgoingMailer.name_for_followup(ir, im).should == "FOI \" Person"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

    it "should quote @ signs" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        im.raw_email.data = im.raw_email.data.sub("FOI Person", "FOI @ Person")
        im.parse_raw_email! true

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "\"FOI @ Person\" <foiperson@localhost>"
        OutgoingMailer.name_for_followup(ir, im).should == "FOI @ Person"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

end

describe OutgoingMailer, "when working out follow up subjects" do

    before(:each) do
        load_raw_emails_data
    end

    it "should prefix the title with 'Freedom of Information request -' for initial requests" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        ir.email_subject_request.should == "Freedom of Information request - Why do you have & such a fancy dog?"
    end

    it "should use 'Re:' and inital request subject for followups which aren't replies to particular messages" do
        ir = info_requests(:fancy_dog_request) 
        om = outgoing_messages(:useless_outgoing_message)

        OutgoingMailer.subject_for_followup(ir, om).should == "Re: Freedom of Information request - Why do you have & such a fancy dog?"
    end

    it "should prefix with Re: the subject of the message being replied to" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        OutgoingMailer.subject_for_followup(ir, om).should == "Re: Geraldine FOI Code AZXB421"
    end

    it "should not add Re: prefix if there already is such a prefix" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: Re: Geraldine FOI Code AZXB421")
        OutgoingMailer.subject_for_followup(ir, om).should == "Re: Geraldine FOI Code AZXB421"
    end

    it "should not add Re: prefix if there already is a lower case re: prefix" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: re: Geraldine FOI Code AZXB421")
        im.parse_raw_email! true
        
        OutgoingMailer.subject_for_followup(ir, om).should == "re: Geraldine FOI Code AZXB421"
    end

    it "should use 'Re:' and initial request subject when replying to failed delivery notifications" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]
        om = outgoing_messages(:useless_outgoing_message)
        om.incoming_message_followup = im

        im.raw_email.data = im.raw_email.data.sub("foiperson@localhost", "postmaster@localhost")
        im.raw_email.data = im.raw_email.data.sub("Subject: Geraldine FOI Code AZXB421", "Subject: Delivery Failed")
        im.parse_raw_email! true

        OutgoingMailer.subject_for_followup(ir, om).should == "Re: Freedom of Information request - Why do you have & such a fancy dog?"
    end
end


