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

    it 'allows a value of external_review' do
      message =
        FactoryGirl.build(:initial_request, :what_doing => 'external_review')
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

  describe '#from' do

    it 'uses the user name and request magic email' do
      user = FactoryGirl.create(:user, :name => 'Spec User 862')
      request = FactoryGirl.create(:info_request, :user => user)
      message = FactoryGirl.build(:initial_request, :info_request => request)
      expected = "Spec User 862 <request-#{ request.id }-#{ request.idhash }@localhost>"
      expect(message.from).to eq(expected)
    end

  end

  describe '#to' do

    context 'when sending an initial request' do

      it 'uses the public body name and email' do
        body = FactoryGirl.create(:public_body, :name => 'Example Public Body',
                                                :short_name => 'EPB')
        request = FactoryGirl.create(:info_request, :public_body => body)
        message = FactoryGirl.build(:initial_request, :info_request => request)
        expected = 'FOI requests at EPB <request@example.com>'
        expect(message.to).to eq(expected)
      end

    end

    context 'when following up to an incoming message' do

      it 'uses the safe_mail_from if the incoming message has a valid address' do
        message = FactoryGirl.build(:internal_review_request)

        followup =
          mock_model(IncomingMessage, :from_email => 'specific@example.com',
                                      :safe_mail_from => 'Specific Person',
                                      :valid_to_reply_to? => true)
        allow(message).to receive(:incoming_message_followup).and_return(followup)

        expected = 'Specific Person <specific@example.com>'
        expect(message.to).to eq(expected)
      end

      it 'uses the public body address if the incoming message has an invalid address' do
        body = FactoryGirl.create(:public_body, :name => 'Example Public Body',
                                                :short_name => 'EPB')
        request = FactoryGirl.create(:info_request, :public_body => body)
        message = FactoryGirl.build(:new_information_followup,
                                    :info_request => request)

        followup =
          mock_model(IncomingMessage, :from_email => 'invalid@example',
                                      :safe_mail_from => 'Specific Person',
                                      :valid_to_reply_to? => false)
        allow(message).to receive(:incoming_message_followup).and_return(followup)

        expected = 'FOI requests at EPB <request@example.com>'
        expect(message.to).to eq(expected)
      end

    end

  end

  describe '#subject' do

    it 'uses the request title with the law prefixed' do
      request = FactoryGirl.create(:info_request, :title => 'Example Request')
      message = FactoryGirl.build(:initial_request, :info_request => request)
      expected = 'Freedom of Information request - Example Request'
      expect(message.subject).to eq(expected)
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

      it 'removes the enclosing angle brackets' do
        message = FactoryGirl.create(:initial_request)
        smtp_id = message.info_request_events.first.params[:smtp_message_id]
        old_format_smtp_id = "<#{ smtp_id }>"
        message.
          info_request_events.
            first.
              update_attributes(:params => {
                                  :smtp_message_id => old_format_smtp_id })
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

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        expect(message.mta_ids).to eq(['1ZsFHb-0004dK-SM'])
      end

      it 'returns an empty array if the mta_id could not be found' do
        message = FactoryGirl.create(:initial_request)
        body_email = message.info_request.public_body.request_email
        request_email = 'unknown@localhost'
        request_subject = 'Unknown'
        smtp_message_id = 'ogm-11+1111111111111-1111@localhost'

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

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

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

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

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 2ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 2ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

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

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 3ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 3ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        expect(message.mta_ids).
          to eq(%w(1ZsFHb-0004dK-SM 2ZsFHb-0004dK-SM))
      end

      it 'returns the known mta_ids if some outgoing messages were not logged' do
        message = FactoryGirl.create(:initial_request)
        body_email = message.info_request.public_body.request_email
        request_email = message.info_request.incoming_email
        request_subject = message.info_request.email_subject_request(:html => false)
        smtp_message_id = 'ogm-14+537f69734b97c-1ebd@localhost'

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 1ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 1ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

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

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-10-30 19:24:16 [17817] 3ZsFHb-0004dK-SM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2297 H=cluster2.gsi.messagelabs.com [127.0.0.1]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail221.messagelabs.com" C="250 ok 1446233056 qp 26062 server-4.tower-221.messagelabs.com!1446233056!7679409!1" QT=1s DT=0s
        2015-10-30 19:24:16 [17814] 3ZsFHb-0004dK-SM <= #{ request_email } U=alaveteli P=local S=2252 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-30 19:24:15 [17814] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        EOF

        expect(message.mta_ids).
          to eq(%w(1ZsFHb-0004dK-SM 3ZsFHb-0004dK-SM))
      end

    end

    describe '#mail_server_logs' do

      it 'finds the mail server logs associated with a sent message' do
        message = FactoryGirl.create(:initial_request)
        body_email = message.info_request.public_body.request_email
        request_email = message.info_request.incoming_email
        request_subject = message.info_request.email_subject_request(:html => false)
        smtp_message_id = 'ogm-14+537f69734b97c-1ebd@localhost'

        load_mail_server_logs <<-EOF.strip_heredoc
        2016-02-03 06:58:10 [16003] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f request-313973-1650c56a@localhost --
        foi@body.example.com
        2016-02-03 06:58:11 [16003] 1aQrOE-0004A7-TL <= request-313973-1650c56a@localhost U=alaveteli P=local S=3098 id=ogm-512169+56b3a50ac0cf4-6717@localhost T="Freedom of Information request - Rspec" from <request-313973-1650c56a@localhost> for foi@body.example.com foi@body.example.com
        2016-02-03 06:58:11 [16006] cwd=/var/spool/exim4 3 args: /usr/sbin/exim4 -Mc 1aQrOE-0004A7-TL
        2016-02-03 06:58:12 [16006] 1aQrOE-0004A7-TL => foi@body.example.com F=<request-313973-1650c56a@localhost> P=<request-313973-1650c56a@localhost> R=dnslookup T=remote_smtp S=3170 H=authority.mail.protection.example.com [213.199.154.87]:25 X=TLS1.2:RSA_AES_256_CBC_SHA256:256 CV=no DN="C=US,ST=WA,L=Redmond,O=Microsoft,OU=Forefront Online Protection for Exchange,CN=mail.protection.outlook.com" C="250 2.6.0 <ogm-512169+56b3a50ac0cf4-6717@localhost> [InternalId=41399189774878, Hostname=HE" QT=2s DT=1s
        2016-02-03 06:58:12 [16006] 1aQrOE-0004A7-TL Completed QT=2s
        2016-02-03 06:58:55 [31388] SMTP connection from [127.0.0.1]:41019 I=[127.0.0.1]:25 (TCP/IP connection count = 1)
        2016-02-03 06:58:56 [16211] 1aQrOx-0004DT-PC <= medications-cheapest5@broadband.hu H=nil.ukcod.org.uk [127.0.0.1]:41019 I=[127.0.0.1]:25 P=esmtp S=31163 T="Spam" from <medications-cheapest5@broadband.hu> for foi@unknown.ukcod.org.uk
        2016-02-03 06:58:56 [16212] cwd=/var/spool/exim4 3 args: /usr/sbin/exim4 -Mc 1aQrOx-0004DT-PC
        2016-02-03 06:58:56 [16211] SMTP connection from nil.ukcod.org.uk [127.0.0.1]:41019 I=[127.0.0.1]:25 closed by QUIT
        2016-02-03 06:58:56 [16287] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ smtp_message_id } -- #{ body_email }
        2016-02-03 06:58:56 [16287] 1aQrOy-0004Eh-H7 <= #{ request_email } U=alaveteli P=local S=2329 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2016-02-03 06:58:56 [16291] cwd=/var/spool/exim4 3 args: /usr/sbin/exim4 -Mc 1aQrOy-0004Eh-H7
        2016-02-03 06:58:57 [16291] 1aQrOy-0004Eh-H7 => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2394 H=cluster1.uk.example.com [85.158.143.3]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail14.messagelabs.com" C="250 ok 1454482737 qp 41621 server-16.tower-14.example.com!1454482736!6386345!1" QT=1s DT=1s
        2016-02-03 06:58:57 [16291] 1aQrOy-0004Eh-H7 Completed QT=1s
        2016-02-03 06:59:17 [16212] 1aQrOx-0004DT-PC => |/home/alaveteli/run-with-rbenv-path /var/www/alaveteli/alaveteli/script/mailin <foi@unknown.ukcod.org.uk> F=<medications-cheapest5@broadband.hu> P=<medications-cheapest5@broadband.hu> R=userforward_unsuffixed T=address_pipe S=31362 QT=22s DT=21s
        2016-02-03 06:59:17 [16212] 1aQrOx-0004DT-PC Completed QT=22s
        2016-02-03 06:59:49 [31388] SMTP connection from [46.235.226.171]:57365 I=[127.0.0.1]:25 (TCP/IP connection count = 1)
        2016-02-03 06:59:49 [16392] SMTP connection from null.ukcod.org.uk (null) [46.235.226.171]:57365 I=[127.0.0.1]:25 closed by QUIT
        2016-02-03 06:59:49 [16392] no MAIL in SMTP connection from null.ukcod.org.uk (null) [46.235.226.171]:57365 I=[127.0.0.1]:25 D=0s C=HELO,QUIT
        EOF

        expected_lines = <<-EOF.strip_heredoc
        2016-02-03 06:58:56 [16287] 1aQrOy-0004Eh-H7 <= #{ request_email } U=alaveteli P=local S=2329 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2016-02-03 06:58:57 [16291] 1aQrOy-0004Eh-H7 => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2394 H=cluster1.uk.example.com [85.158.143.3]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Mountain View,O=Symantec Corporation,OU=Symantec.cloud,CN=mail14.messagelabs.com" C="250 ok 1454482737 qp 41621 server-16.tower-14.example.com!1454482736!6386345!1" QT=1s DT=1s
        EOF

        expect(message.mail_server_logs.map(&:line)).
          to eq(expected_lines.split("\n"))
      end

      it 'finds the mail server logs associated with a resent message' do
        message = FactoryGirl.create(:internal_review_request)
        body_email = message.info_request.public_body.request_email
        request_email = message.info_request.incoming_email
        request_subject = message.info_request.email_subject_request(:html => false)
        smtp_message_id = 'ogm-14+537f69734b97c-1ebd@localhost'

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

        resent_smtp_message_id = mail_message.message_id

        load_mail_server_logs <<-EOF.strip_heredoc
        2015-09-22 17:36:56 [2035] 1ZeQYq-0000Wm-1V => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=1685 H=mail.example.com [62.208.144.158]:25 C="250 2.0.0 Ok: queued as 95FC94583B8" QT=0s DT=0s
        2015-09-22 17:36:56 [2032] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        2015-09-22 17:36:56 [2032] 1ZeQYq-0000Wm-1V <= #{ request_email } U=alaveteli P=local S=1645 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-21 10:28:01 [10354] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        2015-10-21 10:28:01 [10354] 1Zopgf-0002h0-3S <= #{ request_email } U=alaveteli P=local S=1323 id=ogm-+56275aa1046c0-d660@localhost T="Re: #{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-10-21 10:28:01 [10420] 1Zopgf-0002h0-3S => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=1359 H=mail.example.com [62.208.144.158]:25 C="250 2.0.0 Ok: queued as A84A244B926" QT=0s DT=0s
        2015-11-06 10:49:25 [23969] 1ZueaD-0006Eb-Cx <= #{ request_email } U=alaveteli P=local S=1901 id=ogm-+563c85b54d2ed-73c6@localhost T="Internal review of #{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-11-06 10:49:26 [24015] 1ZueaD-0006Eb-Cx => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=1945 H=mail.example.com [62.208.144.158]:25 C="250 2.0.0 Ok: queued as 35671838115" QT=1s DT=1s
        2015-11-06 10:49:25 [23969] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        2015-11-16 20:55:54 [31964] 1ZyQoc-0008JY-DM <= #{ request_email } U=alaveteli P=local S=1910 id=ogm-+564a42da4ea11-8a2e@localhost T="Internal review of #{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-11-16 20:55:55 [31967] 1ZyQoc-0008JY-DM => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=1953 H=mail.example.com [62.208.144.158]:25 C="250 2.0.0 Ok: queued as 03958448DA3" QT=1s DT=1s
        2015-11-16 20:55:54 [31964] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        2015-11-17 05:50:22 [32285] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        2015-11-17 05:50:22 [32285] 1ZyZ9q-0008Oj-JH <= #{ request_email } U=alaveteli P=local S=3413 id=ogm-+564ac01e5ab3c-98e6@localhost T="RE: #{ request_subject } 15" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-11-17 05:50:24 [32288] 1ZyZ9q-0008Oj-JH => #{ body_email } <#{ body_email }> F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=3559 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as 318214E002E" QT=2s DT=2s
        2015-11-22 00:37:01 [17622] 1a0IeK-0004aB-Na => #{ body_email } <#{ body_email }> F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=4137 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as 8878A680030" QT=1s DT=0s
        2015-11-22 00:37:00 [17619] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        2015-11-22 00:37:00 [17619] 1a0IeK-0004aB-Na <= #{ request_email } U=alaveteli P=local S=3973 id=#{ resent_smtp_message_id }@localhost T="RE: #{ request_subject } 15" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-12-01 17:05:37 [26935] 1a3oMy-00070R-SQ <= #{ request_email } U=alaveteli P=local S=2016 id=ogm-+565dd360be2ca-2767@localhost T="Re: #{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-12-01 17:05:36 [26935] cwd=/var/www/alaveteli/alaveteli 7 args: /usr/sbin/sendmail -i -t -f #{ request_email } -- #{ body_email }
        2015-12-01 17:05:38 [26938] 1a3oMy-00070R-SQ => #{ body_email } <#{ body_email }> F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=2071 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as D177C4C002F" QT=2s DT=0s
        EOF

        expected_lines = <<-EOF.strip_heredoc
        2015-09-22 17:36:56 [2035] 1ZeQYq-0000Wm-1V => #{ body_email } F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=1685 H=mail.example.com [62.208.144.158]:25 C="250 2.0.0 Ok: queued as 95FC94583B8" QT=0s DT=0s
        2015-09-22 17:36:56 [2032] 1ZeQYq-0000Wm-1V <= #{ request_email } U=alaveteli P=local S=1645 id=#{ smtp_message_id } T="#{ request_subject }" from <#{ request_email }> for #{ body_email } #{ body_email }
        2015-11-22 00:37:01 [17622] 1a0IeK-0004aB-Na => #{ body_email } <#{ body_email }> F=<#{ request_email }> P=<#{ request_email }> R=dnslookup T=remote_smtp S=4137 H=prefilter.emailsecurity.trendmicro.eu [150.70.226.147]:25 X=TLS1.2:DHE_RSA_AES_128_CBC_SHA1:128 CV=no DN="C=US,ST=California,L=Cupertino,O=Trend Micro Inc.,CN=*.emailsecurity.trendmicro.eu" C="250 2.0.0 Ok: queued as 8878A680030" QT=1s DT=0s
        2015-11-22 00:37:00 [17619] 1a0IeK-0004aB-Na <= #{ request_email } U=alaveteli P=local S=3973 id=#{ resent_smtp_message_id }@localhost T="RE: #{ request_subject } 15" from <#{ request_email }> for #{ body_email } #{ body_email }
        EOF

        expect(message.mail_server_logs.map(&:line)).
          to eq(expected_lines.split("\n"))
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
