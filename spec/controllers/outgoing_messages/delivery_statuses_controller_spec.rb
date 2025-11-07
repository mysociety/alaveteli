require 'spec_helper'

RSpec.describe OutgoingMessages::DeliveryStatusesController do

  let(:logs) do
    lines = <<~EOF.split("\n")
      2015-09-22 17:36:56 [2035] 1ZeQYq-0000Wm-1V => body@example.com F=<request@example.com> P=<request@example.com> R=dnslookup T=remote_smtp S=1685 H=mail.example.com [62.208.144.158]:25 C="250 2.0.0 Ok: queued as 95FC94583B8" QT=0s DT=0s\n
      2015-09-22 17:36:56 [2032] 1ZeQYq-0000Wm-1V <= request@example.com U=alaveteli P=local S=1645 id=ogm-12iu1h22@example.com T="An FOI Request about Potatoes" from <request@example.com> for body@example.com body@example.com\n
      2015-11-22 00:37:01 [17622] 1a0IeK-0004aB-Na => body@example.com <body@example.com> F=<request@example.com> P=<request@example.com> R=dnslookup T=remote_smtp S=4137 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as 8878A680030" QT=1s DT=0s\n
      2015-11-22 00:37:00 [17619] 1a0IeK-0004aB-Na <= request@example.com U=alaveteli P=local S=3973 id=ogm-jh217mwec@example.com@localhost T="RE: An FOI Request about Potatoes 15" from <request@example.com> for body@example.com body@example.com\n
    EOF
    lines.map do |line|
      mock_model(MailServerLog, line: line, :is_owning_user? => true)
    end
  end

  let(:status) { MailServerLog::DeliveryStatus.new(:delivered) }

  describe 'GET show' do
    let(:user) { FactoryBot.create(:user) }
    let(:info_request) { FactoryBot.build(:info_request) }

    let(:message) do
      FactoryBot.create(
        :initial_request, info_request: info_request, prominence: 'normal'
      )
    end

    before do
      sign_in user
      allow(OutgoingMessage).to receive(:find).with('1').and_return(message)
      allow(message).to receive(:mail_server_logs).and_return(logs)
      allow(message).to receive(:delivery_status).and_return(status)
    end

    shared_examples 'authenicated' do
      it 'assigns the outgoing message' do
        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:outgoing_message]).to eq(message)
      end

      it 'sets the title' do
        get :show, params: { outgoing_message_id: 1 }
        expected = "Delivery Status for Outgoing Message ##{message.id}"
        expect(assigns[:title]).to eq(expected)
      end

      it 'assigns the delivery status of the message' do
        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:delivery_status]).to eq(status)
      end

      it 'renders the show template' do
        get :show, params: { outgoing_message_id: 1 }
        expect(response).to render_template('show')
      end
    end

    context 'as request owner' do
      let(:user) { FactoryBot.create(:user) }
      let(:info_request) { FactoryBot.build(:info_request, user: user) }

      include_examples 'authenicated'

      it 'sets show_mail_server_logs to true' do
        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:show_mail_server_logs]).to eq(true)
      end

      it 'assigns the redacted mail server log lines' do
        logs.each do |log|
          expect(log).
            to receive(:line).with(redact: true).and_return(log.line)
        end

        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:mail_server_logs]).to eq(logs.map(&:line))
      end
    end

    context 'as an admin' do
      let(:user) { FactoryBot.create(:admin_user) }
      let(:info_request) { FactoryBot.build(:info_request, user: user) }

      include_examples 'authenicated'

      it 'sets show_mail_server_logs to true' do
        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:show_mail_server_logs]).to eq(true)
      end

      it 'assigns the unredacted mail server log lines' do
        logs.each do |log|
          expect(log).
            to receive(:line).with(redact: false).and_return(log.line)
        end

        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:mail_server_logs]).to eq(logs.map(&:line))
      end
    end

    context 'as other user' do
      include_examples 'authenicated'

      it 'sets show_mail_server_logs to false if the user is not an owner' do
        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:show_mail_server_logs]).to eq(false)
      end

      it 'does not assign mail server logs for a regular user' do
        get :show, params: { outgoing_message_id: 1 }
        expect(assigns[:mail_server_logs]).to eq(nil)
      end
    end

    context 'when the message cannot be viewed' do
      let(:message) do
        FactoryBot.create(
          :initial_request, info_request: info_request, prominence: 'hidden'
        )
      end

      it 'renders hidden' do
        get :show, params: { outgoing_message_id: 1 }
        expect(response).to render_template('request/_prominence')
      end
    end

    context 'when the request cannot be viewed' do
      let(:info_request) do
        FactoryBot.build(:info_request, prominence: 'hidden')
      end

      it 'renders hidden' do
        get :show, params: { outgoing_message_id: 1 }
        expect(response).to render_template('request/_prominence')
      end
    end
  end
end
