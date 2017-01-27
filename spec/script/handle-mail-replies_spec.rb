# -*- encoding : utf-8 -*-
require "spec_helper"
require "external_command"
require File.expand_path(File.dirname(__FILE__) + "/../../script/handle-mail-replies.rb")

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

describe "#forward_on" do
  describe "non-bounce messages" do
    let(:raw_email) { load_file_fixture("normal-contact-reply.email") }
    let(:message) { MailHandler.mail_from_raw_email(raw_email) }

    it "should forward the message to sendmail" do
      expect(IO).
        to receive(:popen).
        with("/usr/sbin/sendmail -i user-support@localhost", "wb")
      forward_on(raw_email, message)
    end
  end
end

describe "#get_forward_to_address" do
  let(:pro_message) do
    raw_email = load_file_fixture("pro-contact-reply.email")
    MailHandler.mail_from_raw_email(raw_email)
  end

  let(:normal_message) do
    raw_email = load_file_fixture("normal-contact-reply.email")
    MailHandler.mail_from_raw_email(raw_email)
  end

  context "if alaveteli pro is disabled" do
    before do
      allow(AlaveteliConfiguration).
        to receive(:enable_alaveteli_pro).and_return(false)
    end

    it "returns the normal forwarding address" do
      expect(get_forward_to_address(normal_message)).
        to eq AlaveteliConfiguration.forward_nonbounce_responses_to
    end
  end

  context "if alaveteli pro is enabled" do
    before do
      allow(AlaveteliConfiguration).
        to receive(:enable_alaveteli_pro).and_return(true)
    end

    context "and the email is replying to the pro contact" do
      it "returns the pro forwarding address" do
        expect(get_forward_to_address(pro_message)).
          to eq AlaveteliConfiguration.forward_pro_nonbounce_responses_to
      end
    end

    context "and the email is replying to the normal contact" do
      it "returns the normal contact address" do
        expect(get_forward_to_address(normal_message)).
          to eq AlaveteliConfiguration.forward_nonbounce_responses_to
      end
    end
  end
end
