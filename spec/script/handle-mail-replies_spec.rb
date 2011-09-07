require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "external_command"

def mail_reply_test(email_filename)
    Dir.chdir RAILS_ROOT do
        xc = ExternalCommand.new("script/handle-mail-replies", "--test")
        xc.run(load_file_fixture(email_filename))
        
        xc.err.should == ""
        return xc
    end
end

describe "When filtering" do
    it "should detect an Exim bounce" do
        r = mail_reply_test("track-response-exim-bounce.email")
        r.status.should == 1
        r.out.should == "user@example.com\n"
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
end

