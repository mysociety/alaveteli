require 'spec_helper'
require "external_command"

def mailin_test(email_filename)
  Dir.chdir Rails.root do
    mail = load_file_fixture(email_filename)
    ir = info_requests(:other_request)
    mail.gsub!('EMAIL_TO', ir.incoming_email)
    mail.gsub!('EMAIL_FROM', 'responder@localhost')
    xc = ExternalCommand.new("script/mailin", stdin_string: mail).run
    expect(xc.err).to eq("")
    return xc
  end
end

RSpec.describe "When importing mail into the application" do
  # Turn off transactional fixtures for this suite - incoming message is imported
  # outside the transaction via ExternalCommand, so needs to be destroyed outside the
  # transaction
  self.use_transactional_tests = false

  around do |example|
    ENV['DISABLE_DEPRECATION_WARNINGS'] = 'true'
    example.call
    ENV['DISABLE_DEPRECATION_WARNINGS'] = nil
  end

  it "should not produce any output and should return a 0 code on importing a plain email" do
    r = mailin_test("incoming-request-empty.email")
    expect(r.status).to eq(0)
    expect(r.out).to eq("")
  end
end
