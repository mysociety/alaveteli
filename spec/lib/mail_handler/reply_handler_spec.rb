require 'spec_helper'
require 'reply_handler'

RSpec.describe MailHandler::ReplyHandler do
  describe '.forward_on' do
    describe 'non-bounce messages' do
      let(:raw_email) { load_file_fixture('normal-contact-reply.email') }
      let(:message) { MailHandler.mail_from_raw_email(raw_email) }

      it 'forwards the message to sendmail' do
        expect(IO).
          to receive(:popen).
          with('/usr/sbin/sendmail -i user-support@localhost', 'wb')
        MailHandler::ReplyHandler.forward_on(raw_email, message)
      end
    end
  end

  describe '.get_forward_to_address' do
    let(:pro_message) do
      raw_email = load_file_fixture('pro-contact-reply.email')
      MailHandler.mail_from_raw_email(raw_email)
    end

    let(:normal_message) do
      raw_email = load_file_fixture('normal-contact-reply.email')
      MailHandler.mail_from_raw_email(raw_email)
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
          MailHandler::ReplyHandler.get_forward_to_address(normal_message)

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
          expect(MailHandler::ReplyHandler.get_forward_to_address(pro_message)).
            to eq(pro_recipient)
        end
      end

      context 'when addressed to the normal contact' do
        it 'returns the normal contact address' do
          address =
            MailHandler::ReplyHandler.get_forward_to_address(normal_message)

          expect(address).to eq(normal_recipient)
        end
      end
    end
  end
end
