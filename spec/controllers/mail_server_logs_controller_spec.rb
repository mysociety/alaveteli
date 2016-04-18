# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MailServerLogsController do

  before do
    lines = <<-EOF.strip_heredoc.split("\n")
    2015-09-22 17:36:56 [2035] 1ZeQYq-0000Wm-1V => body@example.com F=<request@example.com> P=<request@example.com> R=dnslookup T=remote_smtp S=1685 H=mail.example.com [62.208.144.158]:25 C="250 2.0.0 Ok: queued as 95FC94583B8" QT=0s DT=0s\n
    2015-09-22 17:36:56 [2032] 1ZeQYq-0000Wm-1V <= request@example.com U=alaveteli P=local S=1645 id=ogm-12iu1h22@example.com T="An FOI Request about Potatoes" from <request@example.com> for body@example.com body@example.com\n
    2015-11-22 00:37:01 [17622] 1a0IeK-0004aB-Na => body@example.com <body@example.com> F=<request@example.com> P=<request@example.com> R=dnslookup T=remote_smtp S=4137 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as 8878A680030" QT=1s DT=0s\n
    2015-11-22 00:37:00 [17619] 1a0IeK-0004aB-Na <= request@example.com U=alaveteli P=local S=3973 id=ogm-jh217mwec@example.com@localhost T="RE: An FOI Request about Potatoes 15" from <request@example.com> for body@example.com body@example.com\n
    EOF
    @logs = lines.map do |line|
      mock_model(MailServerLog, :line => line, :is_owning_user? => true)
    end
  end

  describe 'GET index' do

    context 'outgoing_message_id param' do

      it 'sets the subject as an outgoing message' do
        message = mock_model(OutgoingMessage, :id => '1',
                                              :user_can_view? => true,
                                              :mail_server_logs => @logs)
        allow(OutgoingMessage).
          to receive(:find).with(message.id).and_return(message)
        get :index, :outgoing_message_id => message.id
        expect(assigns[:subject]).to eq(message)
      end

      it 'renders hidden when the message cannot be viewed' do
        message = mock_model(OutgoingMessage, :id => '1',
                                              :user_can_view? => false,
                                              :mail_server_logs => @logs)
        allow(OutgoingMessage).
          to receive(:find).with(message.id).and_return(message)
        get :index, :outgoing_message_id => message.id
        expect(response).to render_template('request/_hidden_correspondence')
      end

      it 'sets the title' do
        message = mock_model(OutgoingMessage, :id => '1',
                                              :user_can_view? => true,
                                              :mail_server_logs => @logs)
        allow(OutgoingMessage).
          to receive(:find).with(message.id).and_return(message)
        get :index, :outgoing_message_id => message.id
        expected = 'Mail Server Logs for Outgoing Message #1'
        expect(assigns[:title]).to eq(expected)
      end

      it 'assigns the mail server log lines' do
        message = mock_model(OutgoingMessage, :id => '1',
                                              :user_can_view? => true,
                                              :mail_server_logs => @logs)
        allow(OutgoingMessage).
          to receive(:find).with(message.id).and_return(message)
        get :index, :outgoing_message_id => message.id
        expect(assigns[:mail_server_logs]).to eq(@logs.map(&:line))
      end

      it 'redacts email addresses if the user is not the request owner' do
        message = FactoryGirl.create(:initial_request)
        info_request = message.info_request

        line = %Q(2015-11-22 00:37:01 [17622] 1a0IeK-0004aB-Na => body@example.com <body@example.com> F=<#{ info_request.incoming_email }> P=<#{ info_request.incoming_email }> R=dnslookup T=remote_smtp S=4137 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as 8878A680030" QT=1s DT=0s\n)
        log = mock_model(MailServerLog, :line => line,
                                        :is_owning_user? => false)
        allow(message).to receive(:mail_server_logs).and_return([log])

        allow(OutgoingMessage).
          to receive(:find).with(message.id.to_s).and_return(message)
        get :index, :outgoing_message_id => message.id

        expected = [%Q(2015-11-22 00:37:01 [17622] 1a0IeK-0004aB-Na => [email address] <[email address]> F=<[FOI ##{ info_request.id } email]> P=<[FOI ##{ info_request.id } email]> R=dnslookup T=remote_smtp S=4137 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as 8878A680030" QT=1s DT=0s\n)]

        expect(assigns[:mail_server_logs]).to eq(expected)
      end

      it 'renders the index template if the request is for HTML' do
        message = mock_model(OutgoingMessage, :id => '1',
                                              :user_can_view? => true,
                                              :mail_server_logs => @logs)
        allow(OutgoingMessage).
          to receive(:find).with(message.id).and_return(message)
        get :index, :outgoing_message_id => message.id
        expect(response).to render_template('index')
      end

      it 'renders the logs as text if the request is for TEXT' do
        message = mock_model(OutgoingMessage, :id => '1',
                                              :user_can_view? => true,
                                              :mail_server_logs => @logs)
        allow(OutgoingMessage).
          to receive(:find).with(message.id).and_return(message)
        get :index, :format => 'text',
                    :outgoing_message_id => message.id
        expect(response.body).to eq(@logs.map(&:line).join)
      end

    end

  end

end
