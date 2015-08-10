# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "external_command"

def mail_reply_test(email_filename)
  Dir.chdir Rails.root do
    xc = ExternalCommand.new("script/handle-mail-replies", "--test",
                             :stdin_string => load_file_fixture(email_filename))
    xc.run
    expect(xc.err).to eq("")
    return xc
  end
end

describe "When filtering" do

  describe "when not in test mode" do

    it "should not fail handling a bounce mail" do
      xc = ExternalCommand.new("script/handle-mail-replies",
                               { :stdin_string => load_file_fixture("track-response-exim-bounce.email") })
      xc.run
      expect(xc.err).to eq("")
    end

    it 'should not fail handling a UTF8 encoded mail' do
      xc = ExternalCommand.new("script/handle-mail-replies",
                               { :stdin_string => load_file_fixture("russian.email") })
      xc.run
      expect(xc.err).to eq("")
    end
  end

  it "should detect an Exim bounce" do
    r = mail_reply_test("track-response-exim-bounce.email")
    expect(r.status).to eq(1)
    expect(r.out).to eq("user@example.com\n")
  end

  it "should detect a WebShield delivery error message" do
    r = mail_reply_test("track-response-webshield-bounce.email")
    expect(r.status).to eq(1)
    expect(r.out).to eq("failed.user@example.co.uk\n")
  end

  it "should detect a MS Exchange non-permanent delivery error message" do
    r = mail_reply_test("track-response-ms-bounce.email")
    expect(r.status).to eq(1)
    expect(r.out).to eq("")
  end

  it "should pass on a non-bounce message" do
    r = mail_reply_test("incoming-request-bad-uuencoding.email")
    expect(r.status).to eq(0)
    expect(r.out).to eq("")
  end

  it "should detect a multipart bounce" do
    r = mail_reply_test("track-response-multipart-report.email")
    expect(r.status).to eq(1)
    expect(r.out).to eq("FailedUser@example.com\n")
  end

  it "should detect a generic out-of-office" do
    r = mail_reply_test("track-response-generic-oof.email")
    expect(r.status).to eq(2)
  end

  it "should detect an Exchange-style out-of-office" do
    r = mail_reply_test("track-response-exchange-oof-1.email")
    expect(r.status).to eq(2)
  end

  it "should detect a Lotus Domino-style out-of-office" do
    r = mail_reply_test("track-response-lotus-oof-1.email")
    expect(r.status).to eq(2)
  end

  it "should detect a Messagelabs-style out-of-office" do
    r = mail_reply_test("track-response-messagelabs-oof-1.email")
    expect(r.status).to eq(2)
  end

  it "should detect an out-of-office that has an X-POST-MessageClass header" do
    r = mail_reply_test("track-response-messageclass-oof.email")
    expect(r.status).to eq(2)
  end

  it "should detect an Outlook(?)-style out-of-office" do
    r = mail_reply_test("track-response-outlook-oof.email")
    expect(r.status).to eq(2)
  end

  it "should detect an ABCMail-style out-of-office" do
    r = mail_reply_test("track-response-abcmail-oof.email")
    expect(r.status).to eq(2)
  end
end
