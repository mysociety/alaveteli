require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "external_command"

def mail_reply_test(email_filename)
    Dir.chdir Rails.root do
        xc = ExternalCommand.new("script/handle-mail-replies", "--test",
                                 :stdin_string => load_file_fixture(email_filename))
        xc.run
        xc.err.should == ""
        return xc
    end
end

describe "When filtering" do
    it "should not fail when not in test mode" do
        xc = ExternalCommand.new("script/handle-mail-replies",
                                 { :stdin_string => load_file_fixture("track-response-exim-bounce.email") })
        xc.run
        xc.err.should == ""
    end

    it "should detect an Exim bounce" do
        r = mail_reply_test("track-response-exim-bounce.email")
        r.status.should == 1
        r.out.should == "user@example.com\n"
    end

    it "should detect a WebShield delivery error message" do
        r = mail_reply_test("track-response-webshield-bounce.email")
        r.status.should == 1
        r.out.should == "failed.user@example.co.uk\n"
    end

    it "should detect a MS Exchange non-permanent delivery error message" do
        r = mail_reply_test("track-response-ms-bounce.email")
        r.status.should == 1
        r.out.should == ""
    end

    it "should pass on a non-bounce message" do
        r = mail_reply_test("incoming-request-bad-uuencoding.email")
        r.status.should == 0
        r.out.should == ""
    end

    it "should detect a multipart bounce" do
        r = mail_reply_test("track-response-multipart-report.email")
        r.status.should == 1
        r.out.should == "FailedUser@example.com\n"
    end

    it "should detect a generic out-of-office" do
        r = mail_reply_test("track-response-generic-oof.email")
        r.status.should == 2
    end

    it "should detect an Exchange-style out-of-office" do
        r = mail_reply_test("track-response-exchange-oof-1.email")
        r.status.should == 2
    end

    it "should detect a Lotus Domino-style out-of-office" do
        r = mail_reply_test("track-response-lotus-oof-1.email")
        r.status.should == 2
    end

    it "should detect a Messagelabs-style out-of-office" do
        r = mail_reply_test("track-response-messagelabs-oof-1.email")
        r.status.should == 2
    end

    it "should detect an out-of-office that has an X-POST-MessageClass header" do
        r = mail_reply_test("track-response-messageclass-oof.email")
        r.status.should == 2
    end

    it "should detect an Outlook(?)-style out-of-office" do
        r = mail_reply_test("track-response-outlook-oof.email")
        r.status.should == 2
    end

    it "should detect an ABCMail-style out-of-office" do
        r = mail_reply_test("track-response-abcmail-oof.email")
        r.status.should == 2
    end
end

