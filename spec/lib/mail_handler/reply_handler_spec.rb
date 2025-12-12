require 'spec_helper'
require 'mail_handler/reply_handler'

RSpec.describe MailHandler::ReplyHandler do
  describe '.forward_on' do
    describe 'non-bounce mails' do
      let(:inbound_email) { load_file_fixture('normal-contact-reply.eml') }
      let(:mail) { MailHandler.mail_from_string(inbound_email) }

      it 'forwards the mail to sendmail' do
        expect(IO).
          to receive(:popen).
          with('/usr/sbin/sendmail -i "user-support@localhost"', 'wb')
        MailHandler::ReplyHandler.forward_on(inbound_email, mail)
      end
    end
  end

  describe '.get_forward_to_address' do
    let(:normal_contact_email) { AlaveteliConfiguration.contact_email }
    let(:pro_contact_email) { AlaveteliConfiguration.pro_contact_email }

    let(:normal_mail) { get_fixture_mail('normal-contact-reply.eml') }
    let(:pro_mail) { get_fixture_mail('pro-contact-reply.eml') }

    let(:both_mail) do
      MailHandler.mail_from_string(<<~EOF)
      To: #{ normal_contact_email }
      Cc: #{ pro_contact_email }
      From: bob@example.com
      Subject: Sending to both

      Foo Bar baz
      EOF
    end

    let(:normal_recipient) do
      AlaveteliConfiguration.forward_nonbounce_responses_to
    end

    let(:pro_recipient) do
      AlaveteliConfiguration.forward_pro_nonbounce_responses_to
    end

    context 'when alaveteli pro is disabled' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:enable_alaveteli_pro).and_return(false)
      end

      it 'returns the normal forwarding address' do
        address =
          MailHandler::ReplyHandler.get_forward_to_address(normal_mail)

        expect(address).to eq(normal_recipient)
      end
    end

    context 'if alaveteli pro is enabled' do
      before do
        allow(AlaveteliConfiguration).
          to receive(:enable_alaveteli_pro).and_return(true)
      end

      context 'when addressed to the pro contact' do
        it 'returns the pro forwarding address' do
          expect(MailHandler::ReplyHandler.get_forward_to_address(pro_mail)).
            to eq(pro_recipient)
        end
      end

      context 'when addressed to the normal contact' do
        it 'returns the normal contact address' do
          address =
            MailHandler::ReplyHandler.get_forward_to_address(normal_mail)

          expect(address).to eq(normal_recipient)
        end
      end

      context 'when addressed to both contacts' do
        it 'returns the both contact addresses' do
          address =
            MailHandler::ReplyHandler.get_forward_to_address(both_mail)

          expect(address).to eq("#{normal_recipient},#{pro_recipient}")
        end
      end
    end
  end
end
