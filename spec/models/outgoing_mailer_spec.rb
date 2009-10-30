require File.dirname(__FILE__) + '/../spec_helper'

describe OutgoingMailer, " when working out follow up addresses" do
    # This is done with fixtures as the code is a bit tangled with the way it
    # calls TMail.  XXX untangle it and make these tests spread out and using
    # mocks. Put parts of the tests in spec/lib/tmail_extensions.rb
    fixtures :info_requests, :incoming_messages, :raw_emails, :public_bodies

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

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "foiperson@localhost"
        OutgoingMailer.name_for_followup(ir, im).should == "The Geraldine Quango"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

    it "should quote funny characters" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        im.raw_email.data = im.raw_email.data.sub("FOI Person", "FOI [ Person")

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "\"FOI [ Person\" <foiperson@localhost>"
        OutgoingMailer.name_for_followup(ir, im).should == "FOI [ Person"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

    it "should quote quotes" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        im.raw_email.data = im.raw_email.data.sub("FOI Person", "FOI \\\" Person")

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "\"FOI \\\" Person\" <foiperson@localhost>"
        OutgoingMailer.name_for_followup(ir, im).should == "FOI \" Person"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

    it "should quote @ signs" do
        ir = info_requests(:fancy_dog_request) 
        im = ir.incoming_messages[0]

        im.raw_email.data = im.raw_email.data.sub("FOI Person", "FOI @ Person")

        # check the basic entry in the fixture is fine
        OutgoingMailer.name_and_email_for_followup(ir, im).should == "\"FOI @ Person\" <foiperson@localhost>"
        OutgoingMailer.name_for_followup(ir, im).should == "FOI @ Person"
        OutgoingMailer.email_for_followup(ir, im).should == "foiperson@localhost"
    end

end


