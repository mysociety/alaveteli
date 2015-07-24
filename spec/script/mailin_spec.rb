# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "external_command"

def mailin_test(email_filename)
  Dir.chdir Rails.root do

    mail = load_file_fixture(email_filename)
    ir = info_requests(:other_request)
    mail.gsub!('EMAIL_TO', ir.incoming_email)
    mail.gsub!('EMAIL_FROM', 'responder@localhost')
    xc = ExternalCommand.new("script/mailin", :stdin_string => mail).run
    xc.err.should == ""
    return xc
  end
end

describe "When importing mail into the application" do

  # Turn off transactional fixtures for this suite - incoming message is imported
  # outside the transaction via ExternalCommand, so needs to be destroyed outside the
  # transaction
  self.use_transactional_fixtures = false

  it "should not produce any output and should return a 0 code on importing a plain email" do
    r = mailin_test("incoming-request-empty.email")
    r.status.should == 0
    r.out.should == ""
  end

  # Destroy the incoming message so that it doesn't affect other tests
  after do
    ir = info_requests(:other_request)
    incoming_message = ir.incoming_messages[0]
    incoming_message.fully_destroy
    # And get rid of any remaining purge requests
    PurgeRequest.destroy_all
  end

end
