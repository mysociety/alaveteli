require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "external_command"

def mailin_test(email_filename)
    Dir.chdir Rails.root do
        xc = ExternalCommand.new("script/mailin")
        mail = load_file_fixture(email_filename)
        ir = info_requests(:boring_request)
        mail.gsub!('EMAIL_TO', ir.incoming_email)
        mail.gsub!('EMAIL_FROM', 'responder@localhost')
        xc.run(mail)
        xc.err.should == ""
        return xc
    end
end

describe "When importing mail into the application" do

    it "should not produce any output and should return a 0 code on importing a plain email" do
        r = mailin_test("incoming-request-plain.email")
        r.status.should == 0
        r.out.should == ""
    end

end
