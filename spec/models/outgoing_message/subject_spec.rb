require 'spec_helper'

RSpec.describe OutgoingMessage::Subject do
  let(:msg_subject) do
    described_class.new(
      info_request: info_request,
      incoming_message: incoming_message,
      html: html
    )
  end

  let!(:text_request) do
    FactoryBot.create(:info_request, title: 'Just Text')
  end

  let!(:html_request) do
    FactoryBot.create(:info_request, title: 'Fish & Chips')
  end

  # Defaults
  let(:info_request) { text_request }
  let(:incoming_message) { nil }
  let(:html) { true }

  describe '#initial_request' do
    subject { msg_subject.initial_request }

    it "prefixes the title with 'Freedom of Information request -'" do
      is_expected.to eq('Freedom of Information request - Just Text')
    end

    context 'with html in the subject' do
      let(:info_request) { html_request }

      context 'when html is true' do
        it 'escapes HTML in the title' do
          is_expected.to eq('Freedom of Information request - Fish &amp; Chips')
        end
      end

      context 'when html is false' do
        let(:html) { false }

        it 'does not escape HTML in the title' do
          is_expected.to eq('Freedom of Information request - Fish & Chips')
        end
      end
    end
  end

  describe '#followup' do
    subject { msg_subject.followup }

    context 'when there is no incoming message' do
      it 'prefixes the initial request subject with Re:' do
        is_expected.to eq('Re: Freedom of Information request - Just Text')
      end
    end

    context 'when the incoming message is not valid to reply to' do
      let(:incoming_message) do
        mock_model(IncomingMessage, valid_to_reply_to?: false)
      end

      it 'prefixes the initial request subject with Re:' do
        is_expected.to eq('Re: Freedom of Information request - Just Text')
      end
    end

    context 'when the incoming message does not have a subject' do
      let(:incoming_message) do
        mock_model(IncomingMessage, subject: nil, valid_to_reply_to?: true)
      end

      it 'prefixes the initial request subject with Re:' do
        is_expected.to eq('Re: Freedom of Information request - Just Text')
      end
    end

    context 'when the incoming message subject is already prefixed with Re:' do
      let(:incoming_message) do
        mock_model(IncomingMessage, valid_to_reply_to?: true,
                                    subject: 'Re: FOI REF#123456789')
      end

      it 'uses the incoming message subject verbatim' do
        is_expected.to eq('Re: FOI REF#123456789')
      end
    end

    context 'when the incoming message subject has a lower case re: prefix' do
      let(:incoming_message) do
        mock_model(IncomingMessage, valid_to_reply_to?: true,
                                    subject: 're: FOI REF#123456789')
      end

      it 'does not add another Re: prefix' do
        is_expected.to eq('re: FOI REF#123456789')
      end
    end

    context 'when the incoming message subject is not prefixed with Re:' do
      let(:incoming_message) do
        mock_model(IncomingMessage, valid_to_reply_to?: true,
                                    subject: 'FOI REF#123456789')
      end

      it 'prefixes the incoming message subject with Re:' do
        is_expected.to eq('Re: FOI REF#123456789')
      end
    end

    context 'with html in the subject' do
      let(:info_request) { html_request }

      context 'when html is true' do
        it 'escapes HTML in the title' do
          is_expected.
            to eq('Re: Freedom of Information request - Fish &amp; Chips')
        end
      end

      context 'when html is false' do
        let(:html) { false }

        it 'does not escape HTML in the title' do
          is_expected.to eq('Re: Freedom of Information request - Fish & Chips')
        end
      end
    end
  end

  describe '#internal_review' do
    subject { msg_subject.internal_review }

    it "prefixes the request subject with 'Internal review of'" do
      is_expected.to eq('Internal review of Freedom of Information request - ' \
                        'Just Text')
    end

    context 'with html in the subject' do
      let(:info_request) { html_request }

      context 'when html is true' do
        it 'escapes HTML in the title' do
          is_expected.to eq('Internal review of Freedom of Information ' \
                            'request - Fish &amp; Chips')
        end
      end

      context 'when html is false' do
        let(:html) { false }

        it 'does not escape HTML in the title' do
          is_expected.to eq('Internal review of Freedom of Information ' \
                            'request - Fish & Chips')
        end
      end
    end
  end
end
