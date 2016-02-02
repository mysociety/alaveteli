# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: outgoing_messages
#
#  id                           :integer          not null, primary key
#  info_request_id              :integer          not null
#  body                         :text             not null
#  status                       :string(255)      not null
#  message_type                 :string(255)      not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  last_sent_at                 :datetime
#  incoming_message_followup_id :integer
#  what_doing                   :string(255)      not null
#  prominence                   :string(255)      default("normal"), not null
#  prominence_reason            :text
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe OutgoingMessage do

  describe '.fill_in_salutation' do

    it 'replaces the batch request salutation with the body name' do
      text = 'Dear [Authority name],'
      public_body = mock_model(PublicBody, :name => 'A Body')
      expect(described_class.fill_in_salutation(text, public_body)).
        to eq('Dear A Body,')
    end

  end

  describe '#initialize' do

    it 'does not censor the #body' do
      attrs = { :status => 'ready',
                :message_type => 'initial_request',
                :body => 'abc',
                :what_doing => 'normal_sort' }

      message = FactoryGirl.create(:outgoing_message, attrs)

      expect_any_instance_of(OutgoingMessage).not_to receive(:body).and_call_original
      OutgoingMessage.find(message.id)
    end

  end

  describe '#what_doing' do

    it 'allows a value of normal_sort' do
      message =
        FactoryGirl.build(:initial_request, :what_doing => 'normal_sort')
      expect(message).to be_valid
    end

    it 'allows a value of internal_review' do
      message =
        FactoryGirl.build(:initial_request, :what_doing => 'internal_review')
      expect(message).to be_valid
    end

    it 'allows a value of new_information' do
      message =
        FactoryGirl.build(:initial_request, :what_doing => 'new_information')
      expect(message).to be_valid
    end

    it 'adds an error to :what_doing_dummy if an invalid value is provided' do
      message = FactoryGirl.build(:initial_request, :what_doing => 'invalid')
      message.valid?
      expect(message.errors[:what_doing_dummy]).
        to eq(['Please choose what sort of reply you are making.'])
    end

  end

  describe '#destroy' do
    it 'should destroy the outgoing message' do
      attrs = { :status => 'ready',
                :message_type => 'initial_request',
                :body => 'abc',
                :what_doing => 'normal_sort' }
      outgoing_message = FactoryGirl.create(:outgoing_message, attrs)
      outgoing_message.destroy
      expect(OutgoingMessage.where(:id => outgoing_message.id)).to be_empty
    end

    it 'should destroy the associated info_request_events' do
      info_request = FactoryGirl.create(:info_request)
      outgoing_message = info_request.outgoing_messages.first
      outgoing_message.destroy
      expect(InfoRequestEvent.where(:outgoing_message_id => outgoing_message.id)).to be_empty
    end
  end

  describe '#body' do

    it 'returns the body attribute' do
      attrs = { :status => 'ready',
                :message_type => 'initial_request',
                :body => 'abc',
                :what_doing => 'normal_sort' }

      message = FactoryGirl.build(:outgoing_message, attrs)
      expect(message.body).to eq('abc')
    end

    it 'strips the body of leading and trailing whitespace' do
      attrs = { :status => 'ready',
                :message_type => 'initial_request',
                :body => ' abc ',
                :what_doing => 'normal_sort' }

      message = FactoryGirl.build(:outgoing_message, attrs)
      expect(message.body).to eq('abc')
    end

    it 'removes excess linebreaks that unnecessarily space it out' do
      attrs = { :status => 'ready',
                :message_type => 'initial_request',
                :body => "ab\n\nc\n\n",
                :what_doing => 'normal_sort' }

      message = FactoryGirl.build(:outgoing_message, attrs)
      expect(message.body).to eq("ab\n\nc")
    end

    it "applies the associated request's censor rules to the text" do
      attrs = { :status => 'ready',
                :message_type => 'initial_request',
                :body => 'This sensitive text contains secret info!',
                :what_doing => 'normal_sort' }
      message = FactoryGirl.build(:outgoing_message, attrs)

      rules = [FactoryGirl.build(:censor_rule, :text => 'secret'),
               FactoryGirl.build(:censor_rule, :text => 'sensitive')]
      allow_any_instance_of(InfoRequest).to receive(:censor_rules).and_return(rules)

      expected = 'This [REDACTED] text contains [REDACTED] info!'
      expect(message.body).to eq(expected)
    end

    it "applies the given censor rules to the text" do
      attrs = { :status => 'ready',
                :message_type => 'initial_request',
                :body => 'This sensitive text contains secret info!',
                :what_doing => 'normal_sort' }
      message = FactoryGirl.build(:outgoing_message, attrs)

      request_rules = [FactoryGirl.build(:censor_rule, :text => 'secret'),
                       FactoryGirl.build(:censor_rule, :text => 'sensitive')]
      allow_any_instance_of(InfoRequest).to receive(:censor_rules).and_return(request_rules)

      censor_rules = [FactoryGirl.build(:censor_rule, :text => 'text'),
                      FactoryGirl.build(:censor_rule, :text => 'contains')]

      expected = 'This sensitive [REDACTED] [REDACTED] secret info!'
      expect(message.body(:censor_rules => censor_rules)).to eq(expected)
    end

  end

  describe '#get_default_message' do

    context 'an initial_request' do

      it 'produces the expected text for a batch request template' do
        public_body = mock_model(PublicBody, :name => 'a test public body')
        info_request =
          mock_model(InfoRequest, :public_body => public_body,
                                  :url_title => 'a_test_title',
                                  :title => 'a test title',
                                  :applicable_censor_rules => [],
                                  :apply_censor_rules_to_text! => nil,
                                  :is_batch_request_template? => false)
        outgoing_message =
          OutgoingMessage.new(:status => 'ready',
                              :message_type => 'initial_request',
                              :what_doing => 'normal_sort',
                              :info_request => info_request)

        expected_text = "Dear a test public body,\n\n\n\nYours faithfully,\n\n"
        expect(outgoing_message.get_default_message).to eq(expected_text)
      end

    end

    context 'a batch request template' do

      it 'produces the expected text for a batch request template' do
        public_body = mock_model(PublicBody, :name => 'a test public body')
        info_request =
          mock_model(InfoRequest, :public_body => public_body,
                                  :url_title => 'a_test_title',
                                  :title => 'a test title',
                                  :applicable_censor_rules => [],
                                  :apply_censor_rules_to_text! => nil,
                                  :is_batch_request_template? => true)
        outgoing_message =
          OutgoingMessage.new(:status => 'ready',
                              :message_type => 'initial_request',
                              :what_doing => 'normal_sort',
                              :info_request => info_request)

        expected_text = "Dear [Authority name],\n\n\n\nYours faithfully,\n\n"
        expect(outgoing_message.get_default_message).to eq(expected_text)
      end

    end

    context 'a followup' do

      it 'produces the expected text for a followup' do
        public_body = mock_model(PublicBody, :name => 'a test public body')
        info_request =
          mock_model(InfoRequest, :public_body => public_body,
                                  :url_title => 'a_test_title',
                                  :title => 'a test title',
                                  :applicable_censor_rules => [],
                                  :apply_censor_rules_to_text! => nil,
                                  :is_batch_request_template? => false)
        outgoing_message =
          OutgoingMessage.new(:status => 'ready',
                              :message_type => 'followup',
                              :what_doing => 'normal_sort',
                              :info_request => info_request)

        expected_text = "Dear a test public body,\n\n\n\nYours faithfully,\n\n"
        expect(outgoing_message.get_default_message).to eq(expected_text)
      end

      it 'produces the expected text for an incoming message followup' do
        public_body = mock_model(PublicBody, :name => 'a test public body')
        info_request =
          mock_model(InfoRequest, :public_body => public_body,
                                  :url_title => 'a_test_title',
                                  :title => 'a test title',
                                  :applicable_censor_rules => [],
                                  :apply_censor_rules_to_text! => nil,
                                  :is_batch_request_template? => false)
        incoming_message =
          mock_model(IncomingMessage, :safe_mail_from => 'helpdesk',
                                      :valid_to_reply_to? => true)
        outgoing_message =
          OutgoingMessage.new(:status => 'ready',
                              :message_type => 'followup',
                              :what_doing => 'normal_sort',
                              :info_request => info_request,
                              :incoming_message_followup => incoming_message)

        expected_text = "Dear helpdesk,\n\n\n\nYours sincerely,\n\n"
        expect(outgoing_message.get_default_message).to eq(expected_text)
      end

    end

    context 'an internal_review' do

      it 'produces the expected text for an internal review request' do
        public_body = mock_model(PublicBody, :name => 'a test public body')
        info_request =
          mock_model(InfoRequest, :public_body => public_body,
                                  :url_title => 'a_test_title',
                                  :title => 'a test title',
                                  :applicable_censor_rules => [],
                                  :apply_censor_rules_to_text! => nil,
                                  :is_batch_request_template? => false)
        outgoing_message =
          OutgoingMessage.new(:status => 'ready',
                              :message_type => 'followup',
                              :what_doing => 'internal_review',
                              :info_request => info_request)

        expected_text = <<-EOF.strip_heredoc
        Dear a test public body,

        Please pass this on to the person who conducts Freedom of Information reviews.

        I am writing to request an internal review of a test public body's handling of my FOI request 'a test title'.



         [ GIVE DETAILS ABOUT YOUR COMPLAINT HERE ] 



        A full history of my FOI request and all correspondence is available on the Internet at this address: http://test.host/request/a_test_title


        Yours faithfully,

        EOF

        expect(outgoing_message.get_default_message).to eq(expected_text)
      end

    end

  end

  describe '#get_body_for_html_display' do

    before do
      @outgoing_message = OutgoingMessage.new({
                                                :status => 'ready',
                                                :message_type => 'initial_request',
                                                :body => 'This request contains a foo@bar.com email address',
                                                :last_sent_at => Time.now,
                                                :what_doing => 'normal_sort'
      })
    end

    it "does not display email addresses on page" do
      expect(@outgoing_message.get_body_for_html_display).not_to include("foo@bar.com")
    end

    it "links to help page where email address was" do
      expect(@outgoing_message.get_body_for_html_display).to include('<a href="/help/officers#mobiles">')
    end

    it "does not force long lines to wrap" do
      long_line = "long string of 125 characters, set so the old line break " \
                  "falls here, and making sure even longer lines are not " \
                  "affected either"
      @outgoing_message.body = long_line
      expect(@outgoing_message.get_body_for_html_display).to eq("<p>#{long_line}</p>")
    end

    it "interprets single line breaks as <br> tags" do
      split_line = "Hello,\nI am a test message\nWith multiple lines"
      expected = "<p>Hello,\n<br />I am a test message\n<br />With multiple lines</p>"
      @outgoing_message.body = split_line
      expect(@outgoing_message.get_body_for_html_display).to include(expected)
    end

    it "interprets double line breaks as <p> tags" do
      split_line = "Hello,\n\nI am a test message\n\nWith multiple lines"
      expected = "<p>Hello,</p>\n\n<p>I am a test message</p>\n\n<p>With multiple lines</p>"
      @outgoing_message.body = split_line
      expect(@outgoing_message.get_body_for_html_display).to include(expected)
    end

    it "removes excess linebreaks" do
      split_line = "Line 1\n\n\n\n\n\n\n\n\n\nLine 2"
      expected = "<p>Line 1</p>\n\n<p>Line 2</p>"
      @outgoing_message.body = split_line
      expect(@outgoing_message.get_body_for_html_display).to include(expected)
    end

  end

  describe '#indexed_by_search?' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      @outgoing_message = @info_request.outgoing_messages.first
    end

    it 'should return false if it has prominence "hidden"' do
      @outgoing_message.prominence = 'hidden'
      expect(@outgoing_message.indexed_by_search?).to be false
    end

    it 'should return false if it has prominence "requester_only"' do
      @outgoing_message.prominence = 'requester_only'
      expect(@outgoing_message.indexed_by_search?).to be false
    end

    it 'should return true if it has prominence "normal"' do
      @outgoing_message.prominence = 'normal'
      expect(@outgoing_message.indexed_by_search?).to be true
    end

  end

  describe '#user_can_view?' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      @outgoing_message = @info_request.outgoing_messages.first
    end

    context 'if the prominence is hidden' do

      before do
        @outgoing_message.prominence = 'hidden'
      end

      it 'should return true for an admin user' do
        expect(@outgoing_message.user_can_view?(FactoryGirl.create(:admin_user))).to be true
      end

      it 'should return false for a non-admin user' do
        expect(@outgoing_message.user_can_view?(FactoryGirl.create(:user))).to be false
      end

    end

    context 'if the prominence is requester_only' do

      before do
        @outgoing_message.prominence = 'requester_only'
      end

      it 'should return true if the user owns the associated request' do
        expect(@outgoing_message.user_can_view?(@info_request.user)).to be true
      end

      it 'should return false if the user does not own the associated request' do
        expect(@outgoing_message.user_can_view?(FactoryGirl.create(:user))).to be false
      end
    end

    context 'if the prominence is normal' do

      before do
        @outgoing_message.prominence = 'normal'
      end

      it 'should return true for a non-admin user' do
        expect(@outgoing_message.user_can_view?(FactoryGirl.create(:user))).to be true
      end

    end

  end

  describe '#smtp_message_ids' do

    context 'a sent message' do

      it 'returns one smtp_message_id when a message has been sent once' do
        message = FactoryGirl.create(:initial_request)
        smtp_id = message.info_request_events.first.params[:smtp_message_id]
        expect(message.smtp_message_ids).to eq([smtp_id])
      end

      it 'returns an empty array if the smtp_message_id was not logged' do
        message = FactoryGirl.create(:initial_request)
        message.info_request_events.first.update_attributes(:params => {})
        expect(message.smtp_message_ids).to be_empty
      end

    end

    context 'a resent message' do

      it 'returns an smtp_message_id each time the message has been sent' do
        message = FactoryGirl.create(:initial_request)
        smtp_id_1 = message.info_request_events.first.params[:smtp_message_id]

        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id,
          'resent'
        )

        smtp_id_2 = mail_message.message_id

        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id,
          'resent'
        )

        smtp_id_3 = mail_message.message_id

        expect(message.smtp_message_ids).
          to eq([smtp_id_1, smtp_id_2, smtp_id_3])
      end

      it 'returns known smtp_message_ids if some were not logged' do
        message = FactoryGirl.create(:initial_request)
        smtp_id_1 = message.info_request_events.first.params[:smtp_message_id]

        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          nil,
          'resent'
        )

        smtp_id_2 = mail_message.message_id

        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id,
          'resent'
        )

        smtp_id_3 = mail_message.message_id

        expect(message.smtp_message_ids).
          to eq([smtp_id_1, smtp_id_3])
      end

    end

  end

  describe '#mta_ids' do

    context 'a sent message' do

      it 'returns one mta_id when a message has been sent once' do
        message = FactoryGirl.create(:initial_request)
        body_email = message.info_request.public_body.request_email
        request_email = message.info_request.incoming_email
        request_subject = message.info_request.email_subject_request(:html => false)
        smtp_message_id = 'ogm-14+537f69734b97c-1ebd@localhost'

        log = <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        batch = MailServerLogDone.create(:filename => 'spec', :last_stat => Time.now)

        log.split("\n").each_with_index do |line, index|
          MailServerLog.create_exim_log_line(line, batch, index + 1)
        end

        expect(message.mta_ids).to eq(['1ZsFHb-0004dK-SM'])
      end

      it 'returns an empty array if the mta_id could not be found' do
        message = FactoryGirl.create(:initial_request)
        body_email = message.info_request.public_body.request_email
        request_email = 'unknown@localhost'
        request_subject = 'Unknown'
        smtp_message_id = 'ogm-11+1111111111111-1111@localhost'

        log = <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        batch = MailServerLogDone.create(:filename => 'spec', :last_stat => Time.now)

        log.split("\n").each_with_index do |line, index|
          MailServerLog.create_exim_log_line(line, batch, index + 1)
        end

        expect(message.mta_ids).to be_empty
      end

    end

    context 'a resent message' do

      it 'returns an mta_id each time the message has been sent' do
        message = FactoryGirl.create(:initial_request)
        body_email = message.info_request.public_body.request_email
        request_email = message.info_request.incoming_email
        request_subject = message.info_request.email_subject_request(:html => false)
        smtp_message_id = 'ogm-14+537f69734b97c-1ebd@localhost'

        log = <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        batch = MailServerLogDone.create(:filename => 'spec', :last_stat => Time.now)

        log.split("\n").each_with_index do |line, index|
          MailServerLog.create_exim_log_line(line, batch, index + 1)
        end

        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id,
          'resent'
        )

        smtp_message_id = mail_message.message_id

        log = <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 2ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 2ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        batch = MailServerLogDone.create(:filename => 'spec', :last_stat => Time.now)

        log.split("\n").each_with_index do |line, index|
          MailServerLog.create_exim_log_line(line, batch, index + 1)
        end

        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id,
          'resent'
        )

        request_email = 'unknown@localhost'
        request_subject = 'Unknown'
        smtp_message_id = 'ogm-11+1111111111111-1111@localhost'
        smtp_message_id = mail_message.message_id

        log = <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 3ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 3ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        batch = MailServerLogDone.create(:filename => 'spec', :last_stat => Time.now)

        log.split("\n").each_with_index do |line, index|
          MailServerLog.create_exim_log_line(line, batch, index + 1)
        end

        expect(message.mta_ids).
          to eq(%w(1ZsFHb-0004dK-SM 2ZsFHb-0004dK-SM))
      end

      it 'returns the known mta_ids if some outgoing messages were not logged' do
        message = FactoryGirl.create(:initial_request)
        body_email = message.info_request.public_body.request_email
        request_email = message.info_request.incoming_email
        request_subject = message.info_request.email_subject_request(:html => false)
        smtp_message_id = 'ogm-14+537f69734b97c-1ebd@localhost'

        log = <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        batch = MailServerLogDone.create(:filename => 'spec', :last_stat => Time.now)

        log.split("\n").each_with_index do |line, index|
          MailServerLog.create_exim_log_line(line, batch, index + 1)
        end

        # Resend the message without importing exim logs for it, simulating a
        # lost log file or similar.
        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id,
          'resent'
        )

        message.prepare_message_for_resend

        mail_message = OutgoingMailer.initial_request(
          message.info_request,
          message
        ).deliver

        message.record_email_delivery(
          mail_message.to_addrs.join(', '),
          mail_message.message_id,
          'resent'
        )

        smtp_message_id = mail_message.message_id

        log = <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 3ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 3ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        batch = MailServerLogDone.create(:filename => 'spec', :last_stat => Time.now)

        log.split("\n").each_with_index do |line, index|
          MailServerLog.create_exim_log_line(line, batch, index + 1)
        end

        expect(message.mta_ids).
          to eq(%w(1ZsFHb-0004dK-SM 3ZsFHb-0004dK-SM))
      end

    end

  end

end

describe OutgoingMessage, " when making an outgoing message" do

  before do
    @om = outgoing_messages(:useless_outgoing_message)
    @outgoing_message = OutgoingMessage.new({
                                              :status => 'ready',
                                              :message_type => 'initial_request',
                                              :body => 'This request contains a foo@bar.com email address',
                                              :last_sent_at => Time.now,
                                              :what_doing => 'normal_sort'
    })
  end

  it "should not index the email addresses" do
    # also used for track emails
    expect(@outgoing_message.get_text_for_indexing).not_to include("foo@bar.com")
  end


  it "should include email addresses in outgoing messages" do
    expect(@outgoing_message.body).to include("foo@bar.com")
  end

  it 'should produce the expected text for an internal review request' do
    public_body = mock_model(PublicBody, :name => 'A test public body')
    info_request = mock_model(InfoRequest, :public_body => public_body,
                              :url_title => 'a_test_title',
                              :title => 'A test title',
                              :applicable_censor_rules => [],
                              :apply_censor_rules_to_text! => nil,
                              :is_batch_request_template? => false)
    outgoing_message = OutgoingMessage.new({
                                             :status => 'ready',
                                             :message_type => 'followup',
                                             :what_doing => 'internal_review',
                                             :info_request => info_request
    })
    expected_text = "Dear A test public body,\n\nPlease pass this on to the person who conducts Freedom of Information reviews.\n\nI am writing to request an internal review of A test public body's handling of my FOI request 'A test title'.\n\n[ GIVE DETAILS ABOUT YOUR COMPLAINT HERE ] \n\nA full history of my FOI request and all correspondence is available on the Internet at this address: http://test.host/request/a_test_title\n\nYours faithfully,"
    expect(outgoing_message.body).to eq(expected_text)
  end

end

describe OutgoingMessage, "when validating the format of the message body" do

  it 'should handle a salutation with a bracket in it' do
    outgoing_message = FactoryGirl.build(:initial_request)
    allow(outgoing_message).to receive(:get_salutation).and_return("Dear Bob (Robert,")
    expect{ outgoing_message.valid? }.not_to raise_error
  end

end
