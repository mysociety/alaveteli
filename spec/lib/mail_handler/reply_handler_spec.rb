# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'reply_handler'

describe MailHandler::ReplyHandler do
  describe ".forward_on" do
    describe "non-bounce messages" do
      let(:raw_email) { load_file_fixture("normal-contact-reply.email") }
      let(:message) { MailHandler.mail_from_raw_email(raw_email) }

      it "should forward the message to sendmail" do
        expect(IO).
          to receive(:popen).
          with("/usr/sbin/sendmail -i user-support@localhost", "wb")
        MailHandler::ReplyHandler.forward_on(raw_email, message)
      end
    end

    describe 'To: CONTACT_EMAIL Cc: PRO_CONTACT_EMAIL' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:enable_alaveteli_pro).and_return(true)
      end

      let(:raw_email) do
        <<~EOF
        From: bob@localhost
        To: postmaster@localhost
        Cc: pro-contact@localhost
        Subject: Some communication intended to both addresses

        I have a question for both of you.
        EOF
      end

      let(:message) { MailHandler.mail_from_raw_email(raw_email) }

      it "should forward the message to sendmail" do
        expect(IO).
          to receive(:popen).
          with("/usr/sbin/sendmail -it", "wb")
        MailHandler::ReplyHandler.forward_on(raw_email, message)
      end
    end

    describe 'To: PRO_CONTACT_EMAIL Cc: CONTACT_EMAIL' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:enable_alaveteli_pro).and_return(true)
      end

      let(:raw_email) do
        <<~EOF
        From: bob@localhost
        To: pro-contact@localhost
        Cc: postmaster@localhost
        Subject: Some communication intended to both addresses

        I have a question for both of you.
        EOF
      end

      let(:message) { MailHandler.mail_from_raw_email(raw_email) }

      it "should forward the message to sendmail" do
        expect(IO).
          to receive(:popen).
          with("/usr/sbin/sendmail -it", "wb")
        MailHandler::ReplyHandler.forward_on(raw_email, message)
      end
    end
  end

  describe ".get_forward_to_address" do
    let(:pro_message) do
      raw_email = load_file_fixture("pro-contact-reply.email")
      MailHandler.mail_from_raw_email(raw_email)
    end

    let(:normal_message) do
      raw_email = load_file_fixture("normal-contact-reply.email")
      MailHandler.mail_from_raw_email(raw_email)
    end

    let(:both_message) do
      raw_email = load_file_fixture("both-contact-reply.email")
      MailHandler.mail_from_raw_email(raw_email)
    end

    context "if alaveteli pro is disabled" do
      before do
        allow(AlaveteliConfiguration).
          to receive(:enable_alaveteli_pro).and_return(false)
      end

      it "returns the normal forwarding address" do
        expect(MailHandler::ReplyHandler.get_forward_to_address(normal_message)).
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
          expect(MailHandler::ReplyHandler.get_forward_to_address(pro_message)).
            to eq AlaveteliConfiguration.forward_pro_nonbounce_responses_to
        end
      end

      context "and the email is replying to the normal contact" do
        it "returns the normal contact address" do
          expect(MailHandler::ReplyHandler.get_forward_to_address(normal_message)).
            to eq AlaveteliConfiguration.forward_nonbounce_responses_to
        end
      end

      context "and the email is including both contacts" do
        it "returns the both contact addresses" do
          expect(MailHandler::ReplyHandler.get_forward_to_address(both_message)).
            to be_nil
        end
      end
    end
  end
end
