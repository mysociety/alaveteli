# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe OutgoingMessages::DeliveryStatusesController do

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
    @status = MailServerLog::EximDeliveryStatus.new(:normal_message_delivery)
  end

  describe 'GET show' do

    it 'assigns the outgoing message' do
      session[:user_id] = FactoryGirl.create(:user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => true,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(assigns[:outgoing_message]).to eq(message)
    end

    it 'renders hidden when the message cannot be viewed' do
      session[:user_id] = FactoryGirl.create(:user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => false,
                                            :is_owning_user? => false,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(response).to render_template('request/_hidden_correspondence')
    end

    it 'sets the title' do
      session[:user_id] = FactoryGirl.create(:user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => true,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expected = 'Delivery Status for Outgoing Message #1'
      expect(assigns[:title]).to eq(expected)
    end

    it 'assigns the delivery status of the message' do
      @logs.each do |log|
        expect(log).
          to receive(:line).with(:redact_idhash => false).and_return(log.line)
      end

      session[:user_id] = FactoryGirl.create(:admin_user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => true,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(assigns[:delivery_status]).to eq(@status)
    end

    it 'sets show_mail_server_logs to true if the user is an owner' do
      session[:user_id] = FactoryGirl.create(:user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => true,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(assigns[:show_mail_server_logs]).to eq(true)
    end

    it 'sets show_mail_server_logs to false if the user is not an owner' do
      session[:user_id] = FactoryGirl.create(:user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => false,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(assigns[:show_mail_server_logs]).to eq(false)
    end

    it 'assigns the redacted mail server log lines for the request owner' do
      @logs.each do |log|
        expect(log).
          to receive(:line).with(:redact_idhash => true).and_return(log.line)
      end

      session[:user_id] = FactoryGirl.create(:user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => true,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(assigns[:mail_server_logs]).to eq(@logs.map(&:line))
    end

    it 'assigns the unredacted mail server log lines for an admin' do
      @logs.each do |log|
        expect(log).
          to receive(:line).with(:redact_idhash => false).and_return(log.line)
      end

      session[:user_id] = FactoryGirl.create(:admin_user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => true,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(assigns[:mail_server_logs]).to eq(@logs.map(&:line))
    end

    it 'does not assign mail server logs for a regular user' do
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => false,
                                            :mail_server_logs => [],
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(assigns[:mail_server_logs]).to eq(nil)
    end

    it 'renders the show template' do
      session[:user_id] = FactoryGirl.create(:user).id
      message = mock_model(OutgoingMessage, :id => '1',
                                            :user_can_view? => true,
                                            :is_owning_user? => true,
                                            :mail_server_logs => @logs,
                                            :delivery_status => @status)
      allow(OutgoingMessage).
        to receive(:find).with(message.id).and_return(message)
      get :show, :outgoing_message_id => message.id
      expect(response).to render_template('show')
    end

  end

end
