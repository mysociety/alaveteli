# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_requests
#
#  id                        :integer          not null, primary key
#  title                     :text             not null
#  user_id                   :integer
#  public_body_id            :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  described_state           :string(255)      not null
#  awaiting_description      :boolean          default(FALSE), not null
#  prominence                :string(255)      default("normal"), not null
#  url_title                 :text             not null
#  law_used                  :string(255)      default("foi"), not null
#  allow_new_responses_from  :string(255)      default("anybody"), not null
#  handle_rejected_responses :string(255)      default("bounce"), not null
#  idhash                    :string(255)      not null
#  external_user_name        :string(255)
#  external_url              :string(255)
#  attention_requested       :boolean          default(FALSE)
#  comments_allowed          :boolean          default(TRUE), not null
#  info_request_batch_id     :integer
#  last_public_response_at   :datetime
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequest do

  describe '.new' do

    it 'sets the default law used' do
      expect(InfoRequest.new.law_used).to eq('foi')
    end

    it 'sets the default law used if a body is eir-only' do
      body = FactoryGirl.create(:public_body, :tag_string => 'eir_only')
      expect(body.info_requests.build.law_used).to eq('eir')
    end

    it 'does not try to set the law used for existing requests' do
      info_request = FactoryGirl.create(:info_request)
      body = FactoryGirl.create(:public_body, :tag_string => 'eir_only')
      info_request.update_attributes(:public_body_id => body.id)
      expect_any_instance_of(InfoRequest).not_to receive(:law_used=).and_call_original
      InfoRequest.find(info_request.id)
    end

  end

  describe '.stop_new_responses_on_old_requests' do

    it 'does not affect requests that have been updated in the last 6 months' do
      request = FactoryGirl.create(:info_request)
      request.update_attributes(:updated_at => 6.months.ago)
      described_class.stop_new_responses_on_old_requests
      expect(request.reload.allow_new_responses_from).to eq('anybody')
    end

    it 'allows new responses from authority_only after 6 months' do
      request = FactoryGirl.create(:info_request)
      request.update_attributes(:updated_at => 6.months.ago - 1.day)
      described_class.stop_new_responses_on_old_requests
      expect(request.reload.allow_new_responses_from).to eq('authority_only')
    end

    it 'stops new responses after 1 year' do
      request = FactoryGirl.create(:info_request)
      request.update_attributes(:updated_at => 1.year.ago - 1.day)
      described_class.stop_new_responses_on_old_requests
      expect(request.reload.allow_new_responses_from).to eq('nobody')
    end

    context 'when using custom configuration' do

      it 'does not affect requests that have been updated in the last custom number of months' do
        allow(AlaveteliConfiguration).
          to receive(:restrict_new_responses_on_old_requests_after_months).
            and_return(3)

        request = FactoryGirl.create(:info_request)
        request.update_attributes(:updated_at => 3.months.ago)
        described_class.stop_new_responses_on_old_requests
        expect(request.reload.allow_new_responses_from).to eq('anybody')
      end

      it 'allows new responses from authority_only after custom number of months' do
        allow(AlaveteliConfiguration).
          to receive(:restrict_new_responses_on_old_requests_after_months).
            and_return(3)

        request = FactoryGirl.create(:info_request)
        request.update_attributes(:updated_at => 3.months.ago - 1.day)
        described_class.stop_new_responses_on_old_requests
        expect(request.reload.allow_new_responses_from).to eq('authority_only')
      end

      it 'stops new responses after double the custom number of months' do
        allow(AlaveteliConfiguration).
          to receive(:restrict_new_responses_on_old_requests_after_months).
            and_return(3)

        request = FactoryGirl.create(:info_request)
        request.update_attributes(:updated_at => 6.months.ago - 1.day)
        described_class.stop_new_responses_on_old_requests
        expect(request.reload.allow_new_responses_from).to eq('nobody')
      end

    end

  end

  describe '#receive' do

    it 'creates a new incoming message' do
      info_request = FactoryGirl.create(:info_request)
      email, raw_email = email_and_raw_email
      info_request.receive(email, raw_email)
      expect(info_request.incoming_messages.size).to eq(1)
      expect(info_request.incoming_messages.last).to be_persisted
    end

    it 'creates a new raw_email with the incoming email data' do
      info_request = FactoryGirl.create(:info_request)
      email, raw_email = email_and_raw_email
      info_request.receive(email, raw_email)
      expect(info_request.incoming_messages.first.raw_email.data).
        to eq(raw_email)
      expect(info_request.incoming_messages.first.raw_email).to be_persisted
    end

    it 'marks the request as awaiting description' do
      info_request = FactoryGirl.create(:info_request)
      email, raw_email = email_and_raw_email
      info_request.receive(email, raw_email)
      expect(info_request.awaiting_description).to be true
    end

    it 'logs an event' do
      info_request = FactoryGirl.create(:info_request)
      email, raw_email = email_and_raw_email
      info_request.receive(email, raw_email)
      expect(info_request.info_request_events.last.incoming_message.id).
        to eq(info_request.incoming_messages.last.id)
      expect(info_request.info_request_events.last).to be_response
    end

    it 'logs a rejected reason' do
      info_request = FactoryGirl.create(:info_request)
      email, raw_email = email_and_raw_email
      info_request.receive(email, raw_email, false, 'rejected for testing')
      expect(info_request.info_request_events.last.params[:rejected_reason]).
        to eq('rejected for testing')
    end

    context 'notifying the request owner' do

      it 'notifies the user that a response has been received' do
        info_request = FactoryGirl.create(:info_request)
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email)
        notification = ActionMailer::Base.deliveries.last
        expect(notification.to).to include(info_request.user.email)
        expect(ActionMailer::Base.deliveries.size).to eq(1)
        ActionMailer::Base.deliveries.clear
      end

      it 'does not notify when the request is external' do
        info_request = FactoryGirl.create(:external_request)
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email)
        expect(ActionMailer::Base.deliveries).to be_empty
        ActionMailer::Base.deliveries.clear
      end

    end

    context 'allowing new responses' do

      it 'from nobody' do
        attrs = { :allow_new_responses_from => 'nobody',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email)
        holding_pen = InfoRequest.holding_pen_request
        msg = 'This request has been set by an administrator to "allow new ' \
              'responses from nobody"'
        expect(info_request.incoming_messages.size).to eq(0)
        expect(holding_pen.incoming_messages.size).to eq(1)
        expect(holding_pen.info_request_events.last.params[:rejected_reason]).
          to eq(msg)
      end

      it 'from anybody' do
        attrs = { :allow_new_responses_from => 'anybody',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email)
        expect(info_request.incoming_messages.size).to eq(1)
      end

      it 'from authority_only receives if the mail is from the authority' do
        attrs = { :allow_new_responses_from => 'authority_only',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request_with_incoming, attrs)
        email, raw_email = email_and_raw_email(:from => 'bob@example.com')
        info_request.receive(email, raw_email)
        expect(info_request.reload.incoming_messages.size).to eq(2)
      end

      it 'from authority_only rejects if there is no from address' do
        attrs = { :allow_new_responses_from => 'authority_only',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email(:from => '')
        info_request.receive(email, raw_email)
        expect(info_request.reload.incoming_messages.size).to eq(0)
        holding_pen = InfoRequest.holding_pen_request
        expect(holding_pen.incoming_messages.size).to eq(1)
        msg = 'Only the authority can reply to this request, but there is ' \
              'no "From" address to check against'
        expect(holding_pen.info_request_events.last.params[:rejected_reason]).
          to eq(msg)
      end

      it 'from authority_only rejects if the mail is not from the authority' do
        attrs = { :allow_new_responses_from => 'authority_only',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email(:from => 'spam@example.net')
        info_request.receive(email, raw_email)
        expect(info_request.reload.incoming_messages.size).to eq(0)
        holding_pen = InfoRequest.holding_pen_request
        expect(holding_pen.incoming_messages.size).to eq(1)
        msg = "Only the authority can reply to this request, and I don't " \
              "recognise the address this reply was sent from"
        expect(holding_pen.info_request_events.last.params[:rejected_reason]).
          to eq(msg)
      end

      it 'raises an error if there is an unknown allow_new_responses_from' do
        info_request = FactoryGirl.create(:info_request)
        info_request.allow_new_responses_from = 'unknown_value'
        email, raw_email = email_and_raw_email
        err = InfoRequest::ResponseGatekeeper::UnknownResponseGatekeeperError
        expect { info_request.receive(email, raw_email) }.
          to raise_error(err)
      end

      it 'can override the stop new responses status of a request' do
        attrs = { :allow_new_responses_from => 'nobody',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email, true)
        expect(info_request.incoming_messages.size).to eq(1)
      end

      it 'does not check spam when overriding the stop new responses status of a request' do
        mocked_default_config = {
          :spam_action => 'holding_pen',
          :spam_header => 'X-Spam-Score',
          :spam_threshold => 100
        }

        const = 'InfoRequest::' \
                'ResponseGatekeeper::' \
                'SpamChecker::' \
                'DEFAULT_CONFIGURATION'
        stub_const(const, mocked_default_config)

        spam_email = <<-EOF.strip_heredoc
        From: EMAIL_FROM
        To: FOI Person <EMAIL_TO>
        Subject: BUY MY SPAM
        X-Spam-Score: 1000
        Plz buy my spam
        EOF

        attrs = { :allow_new_responses_from => 'nobody',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email(:raw_email => spam_email)
        info_request.receive(email, raw_email, true)
        expect(info_request.incoming_messages.size).to eq(1)
      end

    end

    context 'handling rejected responses' do

      it 'bounces rejected responses if the mail has a from address' do
        attrs = { :allow_new_responses_from => 'nobody',
                  :handle_rejected_responses => 'bounce' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email(:from => 'bounce@example.com')
        info_request.receive(email, raw_email)
        bounce = ActionMailer::Base.deliveries.first
        expect(bounce.to).to include('bounce@example.com')
        ActionMailer::Base.deliveries.clear
      end

      it 'does not bounce responses to external requests' do
        info_request = FactoryGirl.create(:external_request)
        email, raw_email = email_and_raw_email(:from => 'bounce@example.com')
        info_request.receive(email, raw_email)
        expect(ActionMailer::Base.deliveries).to be_empty
        ActionMailer::Base.deliveries.clear
      end

      it 'discards rejected responses if the mail has no from address' do
        attrs = { :allow_new_responses_from => 'nobody',
                  :handle_rejected_responses => 'bounce' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email(:from => '')
        info_request.receive(email, raw_email)
        expect(ActionMailer::Base.deliveries).to be_empty
        ActionMailer::Base.deliveries.clear
      end

      it 'sends rejected responses to the holding pen' do
        attrs = { :allow_new_responses_from => 'nobody',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email)
        expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)
        # Check that the notification that there's something new in the holding
        # has been sent
        expect(ActionMailer::Base.deliveries.size).to eq(1)
        ActionMailer::Base.deliveries.clear
      end

      it 'discards rejected responses' do
        attrs = { :allow_new_responses_from => 'nobody',
                  :handle_rejected_responses => 'blackhole' }
        info_request = FactoryGirl.create(:info_request, attrs)
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email)
        expect(ActionMailer::Base.deliveries).to be_empty
        expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
        ActionMailer::Base.deliveries.clear
      end

      it 'raises an error if there is an unknown handle_rejected_responses' do
        attrs = { :allow_new_responses_from => 'nobody' }
        info_request = FactoryGirl.create(:info_request, attrs)
        info_request.update_attribute(:handle_rejected_responses, 'unknown_value')
        email, raw_email = email_and_raw_email
        err = InfoRequest::ResponseRejection::UnknownResponseRejectionError
        expect { info_request.receive(email, raw_email) }.to raise_error(err)
      end

    end

    it "uses instance-specific spam handling first" do
      info_request = FactoryGirl.create(:info_request)
      info_request.update_attributes!(:handle_rejected_responses => 'bounce',
                                      :allow_new_responses_from => 'nobody')
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_action).and_return('holding_pen')
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_header).and_return('X-Spam-Score')
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_threshold).and_return(100)

      spam_email = <<-EOF.strip_heredoc
      From: EMAIL_FROM
      To: FOI Person <EMAIL_TO>
      Subject: BUY MY SPAM
      X-Spam-Score: 1000
      Plz buy my spam
      EOF

      receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
    end

    it "redirects spam to the holding_pen" do
      info_request = FactoryGirl.create(:info_request)

      mocked_default_config = {
        :spam_action => 'holding_pen',
        :spam_header => 'X-Spam-Score',
        :spam_threshold => 100
      }

      const = 'InfoRequest::' \
              'ResponseGatekeeper::' \
              'SpamChecker::' \
              'DEFAULT_CONFIGURATION'
      stub_const(const, mocked_default_config)

      spam_email = <<-EOF.strip_heredoc
      From: EMAIL_FROM
      To: FOI Person <EMAIL_TO>
      Subject: BUY MY SPAM
      X-Spam-Score: 1000
      Plz buy my spam
      EOF

      receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)
    end

    it "discards mail over the configured spam threshold" do
      info_request = FactoryGirl.create(:info_request)

      mocked_default_config = {
        :spam_action => 'discard',
        :spam_header => 'X-Spam-Score',
        :spam_threshold => 10
      }

      const = 'InfoRequest::' \
              'ResponseGatekeeper::' \
              'SpamChecker::' \
              'DEFAULT_CONFIGURATION'
      stub_const(const, mocked_default_config)

      spam_email = <<-EOF.strip_heredoc
      From: EMAIL_FROM
      To: FOI Person <EMAIL_TO>
      Subject: BUY MY SPAM
      X-Spam-Score: 100

      Plz buy my spam
      EOF

      receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

      expect(ActionMailer::Base.deliveries).to be_empty
      ActionMailer::Base.deliveries.clear
    end

    it "delivers mail under the configured spam threshold" do
      info_request = FactoryGirl.create(:info_request)
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_action).and_return('discard')
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_header).and_return('X-Spam-Score')
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_threshold).and_return(1000)

      spam_email = <<-EOF.strip_heredoc
      From: EMAIL_FROM
      To: FOI Person <EMAIL_TO>
      Subject: BUY MY SPAM
      X-Spam-Score: 100

      Plz buy my spam
      EOF

      receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      ActionMailer::Base.deliveries.clear
    end

    it "delivers mail without a spam header" do
      info_request = FactoryGirl.create(:info_request)
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_action).and_return('discard')
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_header).and_return('X-Spam-Score')
      allow(AlaveteliConfiguration).
        to receive(:incoming_email_spam_threshold).and_return(1000)

      spam_email = <<-EOF.strip_heredoc
      From: EMAIL_FROM
      To: FOI Person <EMAIL_TO>
      Subject: BUY MY SPAM

      Plz buy my spam
      EOF

      receive_incoming_mail(spam_email, info_request.incoming_email, 'spammer@example.com')

      expect(info_request.incoming_messages.size).to eq(1)
      ActionMailer::Base.deliveries.clear
    end

  end

  describe '#move_to_public_body' do

    context 'with no options' do

      it 'requires an :editor option' do
        request = FactoryGirl.create(:info_request)
        new_body = FactoryGirl.create(:public_body)
        expect {
          request.move_to_public_body(new_body)
        }.to raise_error IndexError
      end

    end

    context 'with the :editor option' do

      it 'moves the info request to the new public body' do
        request = FactoryGirl.create(:info_request)
        new_body = FactoryGirl.create(:public_body)
        user = FactoryGirl.create(:user)
        request.move_to_public_body(new_body, :editor => user)
        request.reload
        expect(request.public_body).to eq(new_body)
      end

      it 'logs the move' do
        request = FactoryGirl.create(:info_request)
        old_body = request.public_body
        new_body = FactoryGirl.create(:public_body)
        user = FactoryGirl.create(:user)
        request.move_to_public_body(new_body, :editor => user)
        request.reload
        event = request.info_request_events.last

        expect(event.event_type).to eq('move_request')
        expect(event.params[:editor]).to eq(user)
        expect(event.params[:public_body_url_name]).to eq(new_body.url_name)
        expect(event.params[:old_public_body_url_name]).to eq(old_body.url_name)
      end

      it 'updates the law_used to the new body law' do
        request = FactoryGirl.create(:info_request)
        new_body = FactoryGirl.create(:public_body, :tag_string => 'eir_only')
        user = FactoryGirl.create(:user)
        request.move_to_public_body(new_body, :editor => user)
        request.reload
        expect(request.law_used).to eq('eir')
      end

      it 'returns the new public body' do
        request = FactoryGirl.create(:info_request)
        new_body = FactoryGirl.create(:public_body)
        user = FactoryGirl.create(:user)
        expect(request.move_to_public_body(new_body, :editor => user)).to eq(new_body)
      end

      it 'retains the existing body if the new body does not exist' do
        request = FactoryGirl.create(:info_request)
        user = FactoryGirl.create(:user)
        existing_body = request.public_body
        request.move_to_public_body(nil, :editor => user)
        request.reload
        expect(request.public_body).to eq(existing_body)
      end

      it 'returns nil if the body cannot be updated' do
        request = FactoryGirl.create(:info_request)
        user = FactoryGirl.create(:user)
        expect(request.move_to_public_body(nil, :editor => user)).to eq(nil)
      end

      it 'reindexes the info request' do
        request = FactoryGirl.create(:info_request)
        new_body = FactoryGirl.create(:public_body)
        user = FactoryGirl.create(:user)
        reindex_job = ActsAsXapian::ActsAsXapianJob.
          where(:model => 'InfoRequestEvent').
          delete_all

        request.move_to_public_body(new_body, :editor => user)
        request.reload

        reindex_job = ActsAsXapian::ActsAsXapianJob.
          where(:model => 'InfoRequestEvent').
          last
        expect(reindex_job.model_id).to eq(request.info_request_events.last.id)
      end

    end

  end

  describe '#destroy' do

    let(:info_request) { FactoryGirl.create(:info_request) }

    it "calls update_counter_cache" do
      expect(info_request).to receive(:update_counter_cache)
      info_request.destroy
    end

    it "calls expire" do
      expect(info_request).to receive(:expire)
      info_request.destroy
    end

    it 'destroys associated widget_votes' do
      info_request.widget_votes.create(:cookie => 'x' * 20)
      info_request.destroy
      expect(WidgetVote.where(:info_request_id => info_request.id)).to be_empty
    end

    it 'destroys associated censor_rules' do
      censor_rule = FactoryGirl.create(:censor_rule, :info_request => info_request)
      info_request.reload
      info_request.destroy
      expect(CensorRule.where(:info_request_id => info_request.id)).to be_empty
    end

    it 'destroys associated comments' do
      comment = FactoryGirl.create(:comment, :info_request => info_request)
      info_request.reload
      info_request.destroy
      expect(Comment.where(:info_request_id => info_request.id)).to be_empty
    end

    it 'destroys associated info_request_events' do
      info_request.destroy
      expect(InfoRequestEvent.where(:info_request_id => info_request.id)).to be_empty
    end

    it 'destroys associated outgoing_messages' do
      info_request.destroy
      expect(OutgoingMessage.where(:info_request_id => info_request.id)).to be_empty
    end

    it 'destroys associated incoming_messages' do
      ir_with_incoming = FactoryGirl.create(:info_request_with_incoming)
      ir_with_incoming.destroy
      expect(IncomingMessage.where(:info_request_id => ir_with_incoming.id)).to be_empty
    end

    it 'destroys associated mail_server_logs' do
      MailServerLog.create(:line => 'hi!', :order => 1, :info_request => info_request)
      info_request.destroy
      expect(MailServerLog.where(:info_request_id => info_request.id)).to be_empty
    end

    it 'destroys associated track_things' do
      FactoryGirl.create(:request_update_track,
                         :track_medium => 'email_daily',
                         :info_request => info_request,
                         :track_query => 'Example Query')
      info_request.destroy
      expect(TrackThing.where(:info_request_id => info_request.id)).to be_empty
    end

    it 'destroys associated user_info_request_sent_alerts' do
      UserInfoRequestSentAlert.create(:info_request => info_request,
                                      :user => info_request.user,
                                      :alert_type => 'comment_1')
      info_request.destroy
      expect(UserInfoRequestSentAlert.where(:info_request_id => info_request.id)).to be_empty
    end

  end

  describe '#initial_request_text' do

    it 'returns an empty string if the first outgoing message is hidden' do
      info_request = FactoryGirl.create(:info_request)
      first_message = info_request.outgoing_messages.first
      first_message.prominence = 'hidden'
      first_message.save!
      expect(info_request.initial_request_text).to eq('')
    end

    it 'returns the text of the first outgoing message if it is visible' do
      info_request = FactoryGirl.create(:info_request)
      expect(info_request.initial_request_text).to eq('Some information please')
    end

  end

  describe '#is_external?' do

    it 'returns true if there is an external url' do
      info_request = InfoRequest.new(:external_url => "demo_url")
      expect(info_request.is_external?).to eq(true)
    end

    it 'returns false if there is not an external url' do
      info_request = InfoRequest.new(:external_url => nil)
      expect(info_request.is_external?).to eq(false)
    end

  end

  describe 'when working out which law is in force' do

    context 'when using FOI law' do

      let(:info_request) { InfoRequest.new(:law_used => 'foi') }

      it 'returns the expected law_used_full string' do
        expect(info_request.law_used_human(:full)).to eq("Freedom of Information")
      end

      it 'returns the expected law_used_short string' do
        expect(info_request.law_used_human(:short)).to eq("FOI")
      end

      it 'returns the expected law_used_act string' do
        expect(info_request.law_used_human(:act)).to eq("Freedom of Information Act")
      end

      it 'raises an error when given an unknown key' do
        expect{ info_request.law_used_human(:random) }.to raise_error.
          with_message( "Unknown key 'random' for '#{info_request.law_used}'")
      end

    end

    context 'when using EIR law' do

      let(:info_request) { InfoRequest.new(:law_used => 'eir') }

      it 'returns the expected law_used_full string' do
        expect(info_request.law_used_human(:full)).to eq("Environmental Information Regulations")
      end

      it 'returns the expected law_used_short string' do
        expect(info_request.law_used_human(:short)).to eq("EIR")
      end

      it 'returns the expected law_used_act string' do
        expect(info_request.law_used_human(:act)).to eq("Environmental Information Regulations")
      end

      it 'raises an error when given an unknown key' do
        expect{ info_request.law_used_human(:random) }.to raise_error.
          with_message( "Unknown key 'random' for '#{info_request.law_used}'")
      end

    end

    context 'when set to an unknown law' do

      let(:info_request) { InfoRequest.new(:law_used => 'unknown') }

      it 'raises an error when asked for law_used_full string' do
        expect{ info_request.law_used_human(:full) }.to raise_error.
          with_message("Unknown law used '#{info_request.law_used}'")
      end

      it 'raises an error when asked for law_used_short string' do
        expect{ info_request.law_used_human(:short) }.to raise_error.
          with_message("Unknown law used '#{info_request.law_used}'")
      end

      it 'raises an error when asked for law_used_act string' do
        expect{ info_request.law_used_human(:act) }.to raise_error.
          with_message("Unknown law used '#{info_request.law_used}'")
      end

      it 'raises an error when given an unknown key' do
        expect{ info_request.law_used_human(:random) }.to raise_error.
          with_message("Unknown law used '#{info_request.law_used}'")
      end

    end

  end

  describe 'when validating' do

    it 'requires a summary' do
      info_request = InfoRequest.new
      info_request.valid?
      expect(info_request.errors[:title]).
        to include("Please enter a summary of your request")
    end

    it 'accepts a summary with ascii characters' do
      info_request = InfoRequest.new(:title => 'abcde')
      info_request.valid?
      expect(info_request.errors[:title]).to be_empty
    end

    it 'accepts a summary with unicode characters' do
      info_request = InfoRequest.new(:title => 'кажете')
      info_request.valid?
      expect(info_request.errors[:title]).to be_empty
    end

    it 'rejects a summary with no ascii or unicode characters' do
      info_request = InfoRequest.new(:title => '55555')
      info_request.valid?
      expect(info_request.errors[:title]).
        to include("Please write a summary with some text in it")
    end

    it 'rejects a summary which is more than 200 chars long' do
      info_request = InfoRequest.new(:title => 'Lorem ipsum ' * 17)
      info_request.valid?
      expect(info_request.errors[:title]).
        to include("Please keep the summary short, like in the subject of an " \
                   "email. You can use a phrase, rather than a full sentence.")
    end

    it 'rejects a summary that just says "FOI requests"' do
      info_request = InfoRequest.new(:title => 'FOI requests')
      info_request.valid?
      expect(info_request.errors[:title]).
        to include("Please describe more what the request is about in the " \
                   "subject. There is no need to say it is an FOI request, " \
                   "we add that on anyway.")
    end

    it 'rejects a summary that just says "Freedom of Information request"' do
      info_request = InfoRequest.new(:title => 'Freedom of Information request')
      info_request.valid?
      expect(info_request.errors[:title]).
        to include("Please describe more what the request is about in the " \
                   "subject. There is no need to say it is an FOI request, " \
                   "we add that on anyway.")
    end

    it 'rejects a summary which is not a mix of upper and lower case' do
      info_request = InfoRequest.new(:title => 'lorem ipsum')
      info_request.valid?
      expect(info_request.errors[:title]).
        to include("Please write the summary using a mixture of capital and " \
                   "lower case letters. This makes it easier for others to read.")
    end

    it 'requires a public body id by default' do
      info_request = InfoRequest.new
      info_request.valid?
      expect(info_request.errors[:public_body_id]).to include("can't be blank")
    end

    it 'does not require a public body id if it is a batch request template' do
      info_request = InfoRequest.new
      info_request.is_batch_request_template = true

      info_request.valid?
      expect(info_request.errors[:public_body_id]).to be_empty
    end

  end

  describe 'when generating a user name slug' do

    before do
      @public_body = mock_model(PublicBody, :url_name => 'example_body',
                                :eir_only? => false)
      @info_request = InfoRequest.new(:external_url => 'http://www.example.com',
                                      :external_user_name => 'Example User',
                                      :public_body => @public_body)
    end

    it 'should generate a slug for an example user name' do
      expect(@info_request.user_name_slug).to eq('example_body_example_user')
    end

  end

  describe "guessing a request from an email" do

    before(:each) do
      @im = incoming_messages(:useless_incoming_message)
      load_raw_emails_data
    end

    it 'computes a hash' do
      @info_request = InfoRequest.new(:title => "testing",
                                      :public_body => public_bodies(:geraldine_public_body),
                                      :user_id => 1)
      @info_request.save!
      expect(@info_request.idhash).not_to eq(nil)
    end

    it 'finds a request based on an email with an intact id and a broken hash' do
      ir = info_requests(:fancy_dog_request)
      id = ir.id
      @im.mail.to = "request-#{id}-asdfg@example.com"
      guessed = InfoRequest.guess_by_incoming_email(@im)
      expect(guessed[0].idhash).to eq(ir.idhash)
    end

    it 'finds a request based on an email with a broken id and an intact hash' do
      ir = info_requests(:fancy_dog_request)
      idhash = ir.idhash
      @im.mail.to = "request-123ab-#{idhash}@example.com"
      guessed = InfoRequest.guess_by_incoming_email(@im)
      expect(guessed[0].id).to eq(ir.id)
    end

  end

  describe "making up the URL title" do

    before do
      @info_request = InfoRequest.new
    end

    it 'removes spaces, and makes lower case' do
      @info_request.title = 'Something True'
      expect(@info_request.url_title).to eq('something_true')
    end

    it 'does not allow a numeric title' do
      @info_request.title = '1234'
      expect(@info_request.url_title).to eq('request')
    end

  end

  describe "when asked for the last event id that needs description" do

    before do
      @info_request = InfoRequest.new
    end

    it 'returns the last undescribed event id if there is one' do
      last_mock_event = mock_model(InfoRequestEvent)
      other_mock_event = mock_model(InfoRequestEvent)
      allow(@info_request).to receive(:events_needing_description).and_return([other_mock_event, last_mock_event])
      expect(@info_request.last_event_id_needing_description).to eq(last_mock_event.id)
    end

    it 'returns zero if there are no undescribed events' do
      allow(@info_request).to receive(:events_needing_description).and_return([])
      expect(@info_request.last_event_id_needing_description).to eq(0)
    end

  end

  describe 'when managing the cache directories' do

    before do
      @info_request = info_requests(:fancy_dog_request)
    end

    it 'returns the default locale cache path without locale parts' do
      default_locale_path = File.join(Rails.root, 'cache', 'views', 'request', '101', '101')
      expect(@info_request.foi_fragment_cache_directories.include?(default_locale_path)).to eq(true)
    end

    it 'returns the cache path for any other locales' do
      other_locale_path =  File.join(Rails.root, 'cache', 'views', 'es', 'request', '101', '101')
      expect(@info_request.foi_fragment_cache_directories.include?(other_locale_path)).to eq(true)
    end

  end

  describe "when emailing" do

    before do
      @info_request = info_requests(:fancy_dog_request)
    end

    it "has a valid incoming email" do
      expect(@info_request.incoming_email).not_to be_nil
    end

    it "has a sensible incoming name and email" do
      expect(@info_request.incoming_name_and_email).to eq("Bob Smith <" + @info_request.incoming_email + ">")
    end

    it "has a sensible recipient name and email" do
      expect(@info_request.recipient_name_and_email).to eq("FOI requests at TGQ <geraldine-requests@localhost>")
    end

    it "recognises its own incoming email" do
      incoming_email = @info_request.incoming_email
      found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
      expect(found_info_request).to eq(@info_request)
    end

    it "recognises its own incoming email with some capitalisation" do
      incoming_email = @info_request.incoming_email.gsub(/request/, "Request")
      found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
      expect(found_info_request).to eq(@info_request)
    end

    it "recognises its own incoming email with quotes" do
      incoming_email = "'" + @info_request.incoming_email + "'"
      found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
      expect(found_info_request).to eq(@info_request)
    end

    it "recognises l and 1 as the same in incoming emails" do
      # Make info request with a 1 in it
      while true
        ir = InfoRequest.new(:title => "testing", :public_body => public_bodies(:geraldine_public_body),
                             :user => users(:bob_smith_user))
        ir.save!
        hash_part = ir.incoming_email.match(/-[0-9a-f]+@/)[0]
        break if hash_part.match(/1/)
      end

      # Make email with a 1 in the hash part changed to l
      test_email = ir.incoming_email
      new_hash_part = hash_part.gsub(/1/, "l")
      test_email.gsub!(hash_part, new_hash_part)

      # Try and find with an l
      found_info_request = InfoRequest.find_by_incoming_email(test_email)
      expect(found_info_request).to eq(ir)
    end

    it "recognises old style request-bounce- addresses" do
      incoming_email = @info_request.magic_email("request-bounce-")
      found_info_request = InfoRequest.find_by_incoming_email(incoming_email)
      expect(found_info_request).to eq(@info_request)
    end

    it "returns nil when receiving email for a deleted request" do
      deleted_request_address = InfoRequest.magic_email_for_id("request-", 98765)
      found_info_request = InfoRequest.find_by_incoming_email(deleted_request_address)
      expect(found_info_request).to be_nil
    end

    it "copes with indexing after item is deleted" do
      load_raw_emails_data
      IncomingMessage.find(:all).each{|x| x.parse_raw_email!}
      rebuild_xapian_index
      # delete event from underneath indexing; shouldn't cause error
      info_request_events(:useless_incoming_message_event).save!
      info_request_events(:useless_incoming_message_event).destroy
      update_xapian_index
    end

  end

  describe "when calculating the status" do

    before do
      @ir = info_requests(:naughty_chicken_request)
    end

    it "has expected sent date" do
      expect(@ir.last_event_forming_initial_request.outgoing_message.last_sent_at.strftime("%F")).to eq('2007-10-14')
    end

    it "has correct due date" do
      expect(@ir.date_response_required_by.strftime("%F")).to eq('2007-11-09')
    end

    it "has correct very overdue after date" do
      expect(@ir.date_very_overdue_after.strftime("%F")).to eq('2007-12-10')
    end

    it "isn't overdue on due date (20 working days after request sent)" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 9, 23, 59))
      expect(@ir.calculate_status).to eq('waiting_response')
    end

    it "is overdue a day after due date (20 working days after request sent)" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 10, 00, 01))
      expect(@ir.calculate_status).to eq('waiting_response_overdue')
    end

    it "is still overdue 40 working days after request sent" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 12, 10, 23, 59))
      expect(@ir.calculate_status).to eq('waiting_response_overdue')
    end

    it "is very overdue the day after 40 working days after request sent" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 12, 11, 00, 01))
      expect(@ir.calculate_status).to eq('waiting_response_very_overdue')
    end

  end

  describe "when using a plugin and calculating the status" do

    before do
      InfoRequest.send(:require, File.expand_path(File.dirname(__FILE__) + '/customstates'))
      InfoRequest.send(:include, InfoRequestCustomStates)
      InfoRequest.class_eval('@@custom_states_loaded = true')
      @ir = info_requests(:naughty_chicken_request)
    end

    it "rejects invalid states" do
      expect {@ir.set_described_state("foo")}.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "accepts core states" do
      @ir.set_described_state("successful")
    end

    it "accepts extended states" do
      # this time would normally be "overdue"
      allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 10, 00, 01))
      @ir.set_described_state("deadline_extended")
      expect(@ir.display_status).to eq('Deadline extended.')
      @ir.date_deadline_extended
    end

    it "is not overdue if it's had the deadline extended" do
      when_overdue = Time.utc(2007, 11, 10, 00, 01) + 16.days
      allow(Time).to receive(:now).and_return(when_overdue)
      expect(@ir.calculate_status).to eq('waiting_response_overdue')
    end

  end

  describe "when calculating the status for a school" do

    before do
      @ir = info_requests(:naughty_chicken_request)
      @ir.public_body.tag_string = "school"
      expect(@ir.public_body.is_school?).to eq(true)
    end

    it "has expected sent date" do
      expect(@ir.last_event_forming_initial_request.outgoing_message.last_sent_at.strftime("%F")).to eq('2007-10-14')
    end

    it "has correct due date" do
      expect(@ir.date_response_required_by.strftime("%F")).to eq('2007-11-09')
    end

    it "has correct very overdue after date" do
      expect(@ir.date_very_overdue_after.strftime("%F")).to eq('2008-01-11') # 60 working days for schools
    end

    it "isn't overdue on due date (20 working days after request sent)" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 9, 23, 59))
      expect(@ir.calculate_status).to eq('waiting_response')
    end

    it "is overdue a day after due date (20 working days after request sent)" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 10, 00, 01))
      expect(@ir.calculate_status).to eq('waiting_response_overdue')
    end

    it "is still overdue 40 working days after request sent" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 12, 10, 23, 59))
      expect(@ir.calculate_status).to eq('waiting_response_overdue')
    end

    it "is still overdue the day after 40 working days after request sent" do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 12, 11, 00, 01))
      expect(@ir.calculate_status).to eq('waiting_response_overdue')
    end

    it "is still overdue 60 working days after request sent" do
      allow(Time).to receive(:now).and_return(Time.utc(2008, 01, 11, 23, 59))
      expect(@ir.calculate_status).to eq('waiting_response_overdue')
    end

    it "is very overdue the day after 60 working days after request sent" do
      allow(Time).to receive(:now).and_return(Time.utc(2008, 01, 12, 00, 01))
      expect(@ir.calculate_status).to eq('waiting_response_very_overdue')
    end

  end

  describe 'when asked if a user is the owning user for this request' do

    before do
      @mock_user = mock_model(User)
      @info_request = InfoRequest.new(:user => @mock_user)
      @other_mock_user = mock_model(User)
    end

    it 'returns false if a nil object is passed to it' do
      expect(@info_request.is_owning_user?(nil)).to be false
    end

    it 'returns true if the user is the request\'s owner' do
      expect(@info_request.is_owning_user?(@mock_user)).to be true
    end

    it 'returns false for a user that is not the owner and does not own every request' do
      allow(@other_mock_user).to receive(:owns_every_request?).and_return(false)
      expect(@info_request.is_owning_user?(@other_mock_user)).to be false
    end

    it 'returns true if the user is not the owner but owns every request' do
      allow(@other_mock_user).to receive(:owns_every_request?).and_return(true)
      expect(@info_request.is_owning_user?(@other_mock_user)).to be true
    end

  end

  describe 'when asked if it requires admin' do

    before do
      @info_request = InfoRequest.new
    end

    it 'returns true if its described state is error_message' do
      @info_request.described_state = 'error_message'
      expect(@info_request.requires_admin?).to be true
    end

    it 'returns true if its described state is requires_admin' do
      @info_request.described_state = 'requires_admin'
      expect(@info_request.requires_admin?).to be true
    end

    it 'returns false if its described state is waiting_response' do
      @info_request.described_state = 'waiting_response'
      expect(@info_request.requires_admin?).to be false
    end

  end

  describe 'when asked for old unclassified requests' do

    it 'asks for requests using any limit param supplied' do
      expect(InfoRequest).to receive(:find).
        with(:all, hash_including(:limit => 5))
      InfoRequest.find_old_unclassified(:limit => 5)
    end

    it 'asks for requests using any offset param supplied' do
      expect(InfoRequest).to receive(:find).
        with(:all, hash_including(:offset => 100))
      InfoRequest.find_old_unclassified(:offset => 100)
    end

    it 'does not limit the number of requests returned by default' do
      expect(InfoRequest).to receive(:find).
        with(:all, hash_excluding(:limit => anything))
      InfoRequest.find_old_unclassified
    end

    it 'adds extra conditions if supplied' do
      expect(InfoRequest).to receive(:find).
        with(:all, hash_including(
          {:conditions => include(/prominence != 'backpage'/)}))
      InfoRequest.find_old_unclassified({:conditions => ["prominence != 'backpage'"]})
    end

    context "returning records" do
      let(:recent_date) { Time.zone.now - 20.days }
      let(:old_date) { Time.zone.now - 22.days }
      let(:user) { FactoryGirl.create(:user) }

      def create_recent_unclassified_request
        request = FactoryGirl.create(:info_request, :user => user,
                                                    :created_at => recent_date)
        message = FactoryGirl.create(:incoming_message, :created_at => recent_date,
                                                        :info_request => request)
        FactoryGirl.create(:info_request_event, :incoming_message => message,
                                                :event_type => "response",
                                                :info_request => request,
                                                :created_at => recent_date)
        request.awaiting_description = true
        request.save
        request
      end

      def create_old_unclassified_request
        request = FactoryGirl.create(:info_request, :user => user,
                                                    :created_at => old_date)
        message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                        :info_request => request)
        FactoryGirl.create(:info_request_event, :incoming_message => message,
                                                :event_type => "response",
                                                :info_request => request,
                                                :created_at => old_date)
        request.awaiting_description = true
        request.save
        request
      end

      def create_old_unclassified_described
        request = FactoryGirl.create(:info_request, :user => user,
                                                    :created_at => old_date)
        message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                        :info_request => request)
        FactoryGirl.create(:info_request_event, :incoming_message => message,
                                                :event_type => "response",
                                                :info_request => request,
                                                :created_at => old_date)
        request
      end

      def create_old_unclassified_no_user
        request = FactoryGirl.create(:info_request, :user => nil,
                                                    :external_user_name => 'test_user',
                                                    :external_url => 'test',
                                                    :created_at => old_date)
        message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                        :info_request => request)
        FactoryGirl.create(:info_request_event, :incoming_message => message,
                                                :event_type => "response",
                                                :info_request => request,
                                                :created_at => old_date)
        request.awaiting_description = true
        request.save
        request
      end

      def create_old_unclassified_holding_pen
        request = FactoryGirl.create(:info_request, :user => user,
                                                    :url_title => 'holding_pen',
                                                    :created_at => old_date)
        message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                        :info_request => request)
        FactoryGirl.create(:info_request_event, :incoming_message => message,
                                                :event_type => "response",
                                                :info_request => request,
                                                :created_at => old_date)
        request.awaiting_description = true
        request.save
        request
      end


      it "returns records over 21 days old" do
        old_unclassified_request = create_old_unclassified_request
        results = InfoRequest.find_old_unclassified
        expect(results).to include(old_unclassified_request)
      end

      it "does not return records less than 21 days old" do
        recent_unclassified_request = create_recent_unclassified_request
        results = InfoRequest.find_old_unclassified
        expect(results).not_to include(recent_unclassified_request)
      end

      it "only returns records with an associated user" do
        old_unclassified_no_user = create_old_unclassified_no_user
        results = InfoRequest.find_old_unclassified
        expect(results).not_to include(old_unclassified_no_user)
      end

      it "only returns records which are awaiting description" do
        old_unclassified_described = create_old_unclassified_described
        results = InfoRequest.find_old_unclassified
        expect(results).not_to include(old_unclassified_described)
      end

      it "does not return anything which is in the holding pen" do
        old_unclassified_holding_pen = create_old_unclassified_holding_pen
        results = InfoRequest.find_old_unclassified
        expect(results).not_to include(old_unclassified_holding_pen)
      end
    end

  end

  describe 'when asked for random old unclassified requests with normal prominence' do

    it "does not return requests that don't have normal prominence" do
      dog_request = info_requests(:fancy_dog_request)
      old_unclassified = InfoRequest.get_random_old_unclassified(1, :conditions => ["prominence = 'normal'"])
      expect(old_unclassified.length).to eq(1)
      expect(old_unclassified.first).to eq(dog_request)
      dog_request.prominence = 'requester_only'
      dog_request.save!
      old_unclassified = InfoRequest.get_random_old_unclassified(1, :conditions => ["prominence = 'normal'"])
      expect(old_unclassified.length).to eq(0)
      dog_request.prominence = 'hidden'
      dog_request.save!
      old_unclassified = InfoRequest.get_random_old_unclassified(1, :conditions => ["prominence = 'normal'"])
      expect(old_unclassified.length).to eq(0)
    end

  end

  describe 'when asked to count old unclassified requests with normal prominence' do

    it "does not return requests that don't have normal prominence" do
      dog_request = info_requests(:fancy_dog_request)
      old_unclassified = InfoRequest.count_old_unclassified(:conditions => ["prominence = 'normal'"])
      expect(old_unclassified).to eq(1)
      dog_request.prominence = 'requester_only'
      dog_request.save!
      old_unclassified = InfoRequest.count_old_unclassified(:conditions => ["prominence = 'normal'"])
      expect(old_unclassified).to eq(0)
      dog_request.prominence = 'hidden'
      dog_request.save!
      old_unclassified = InfoRequest.count_old_unclassified(:conditions => ["prominence = 'normal'"])
      expect(old_unclassified).to eq(0)
    end

  end

  describe 'when an instance is asked if it is old and unclassified' do

    before do
      allow(Time).to receive(:now).and_return(Time.utc(2007, 11, 9, 23, 59))
      @info_request = FactoryGirl.create(:info_request,
                                         :prominence => 'normal',
                                         :awaiting_description => true)
      @comment_event = FactoryGirl.create(:info_request_event,
                                          :created_at => Time.now - 23.days,
                                          :event_type => 'comment',
                                          :info_request => @info_request)
      @incoming_message = FactoryGirl.create(:incoming_message,
                                             :prominence => 'normal',
                                             :info_request => @info_request)
      @response_event = FactoryGirl.create(:info_request_event,
                                           :info_request => @info_request,
                                           :created_at => Time.now - 22.days,
                                           :event_type => 'response',
                                           :incoming_message => @incoming_message)
      @info_request.update_attribute(:awaiting_description, true)
    end

    it 'returns false if it is the holding pen' do
      allow(@info_request).to receive(:url_title).and_return('holding_pen')
      expect(@info_request.is_old_unclassified?).to be false
    end

    it 'returns false if it is not awaiting description' do
      allow(@info_request).to receive(:awaiting_description).and_return(false)
      expect(@info_request.is_old_unclassified?).to be false
    end

    it 'returns false if its last response event occurred less than 21 days ago' do
      @response_event.update_attribute(:created_at, Time.now - 20.days)
      expect(@info_request.is_old_unclassified?).to be false
    end

    it 'returns true if it is awaiting description, isn\'t the holding pen and hasn\'t had an event in 21 days' do
      expect(@info_request.is_external? || @info_request.is_old_unclassified?).to be true
    end

  end

  describe 'when applying censor rules' do

    before do
      @global_rule = mock_model(CensorRule, :apply_to_text! => nil,
                                :apply_to_binary! => nil)
      @user_rule = mock_model(CensorRule, :apply_to_text! => nil,
                              :apply_to_binary! => nil)
      @request_rule = mock_model(CensorRule, :apply_to_text! => nil,
                                 :apply_to_binary! => nil)
      @body_rule = mock_model(CensorRule, :apply_to_text! => nil,
                              :apply_to_binary! => nil)
      @user = mock_model(User, :censor_rules => [@user_rule])
      @body = mock_model(PublicBody, :censor_rules => [@body_rule])
      @info_request = InfoRequest.new(:prominence => 'normal',
                                      :awaiting_description => true,
                                      :title => 'title')
      allow(@info_request).to receive(:user).and_return(@user)
      allow(@info_request).to receive(:censor_rules).and_return([@request_rule])
      allow(@info_request).to receive(:public_body).and_return(@body)
      @text = 'some text'
      allow(CensorRule).to receive(:global).and_return(double('global context', :all => [@global_rule]))
    end

    context "when applying censor rules to text" do

      it "applies a global censor rule" do
        expect(@global_rule).to receive(:apply_to_text!).with(@text)
        @info_request.apply_censor_rules_to_text!(@text)
      end

      it 'applies a user rule' do
        expect(@user_rule).to receive(:apply_to_text!).with(@text)
        @info_request.apply_censor_rules_to_text!(@text)
      end

      it 'does not raise an error if there is no user' do
        @info_request.user_id = nil
        expect{ @info_request.apply_censor_rules_to_text!(@text) }.not_to raise_error
      end

      it 'applies a rule from the body associated with the request' do
        expect(@body_rule).to receive(:apply_to_text!).with(@text)
        @info_request.apply_censor_rules_to_text!(@text)
      end

      it 'applies a request rule' do
        expect(@request_rule).to receive(:apply_to_text!).with(@text)
        @info_request.apply_censor_rules_to_text!(@text)
      end

      it 'does not raise an error if the request is a batch request template' do
        allow(@info_request).to receive(:public_body).and_return(nil)
        @info_request.is_batch_request_template = true
        expect{ @info_request.apply_censor_rules_to_text!(@text) }.not_to raise_error
      end

    end

    context 'when applying censor rules to binary files' do

      it "applies a global censor rule" do
        expect(@global_rule).to receive(:apply_to_binary!).with(@text)
        @info_request.apply_censor_rules_to_binary!(@text)
      end

      it 'applies a user rule' do
        expect(@user_rule).to receive(:apply_to_binary!).with(@text)
        @info_request.apply_censor_rules_to_binary!(@text)
      end

      it 'does not raise an error if there is no user' do
        @info_request.user_id = nil
        expect{ @info_request.apply_censor_rules_to_binary!(@text) }.not_to raise_error
      end

      it 'applies a rule from the body associated with the request' do
        expect(@body_rule).to receive(:apply_to_binary!).with(@text)
        @info_request.apply_censor_rules_to_binary!(@text)
      end

      it 'applies a request rule' do
        expect(@request_rule).to receive(:apply_to_binary!).with(@text)
        @info_request.apply_censor_rules_to_binary!(@text)
      end

    end

  end

  describe 'when an instance is asked if all can view it' do

    before do
      @info_request = InfoRequest.new
    end

    it 'returns true if its prominence is normal' do
      @info_request.prominence = 'normal'
      expect(@info_request.all_can_view?).to eq(true)
    end

    it 'returns true if its prominence is backpage' do
      @info_request.prominence = 'backpage'
      expect(@info_request.all_can_view?).to eq(true)
    end

    it 'returns false if its prominence is hidden' do
      @info_request.prominence = 'hidden'
      expect(@info_request.all_can_view?).to eq(false)
    end

    it 'returns false if its prominence is requester_only' do
      @info_request.prominence = 'requester_only'
      expect(@info_request.all_can_view?).to eq(false)
    end

  end

  describe 'when asked for the last public response event' do

    before do
      @info_request = FactoryGirl.create(:info_request_with_incoming)
      @incoming_message = @info_request.incoming_messages.first
    end

    it 'does not return an event with a hidden prominence message' do
      @incoming_message.prominence = 'hidden'
      @incoming_message.save!
      expect(@info_request.get_last_public_response_event).to eq(nil)
    end

    it 'does not return an event with a requester_only prominence message' do
      @incoming_message.prominence = 'requester_only'
      @incoming_message.save!
      expect(@info_request.get_last_public_response_event).to eq(nil)
    end

    it 'returns an event with a normal prominence message' do
      @incoming_message.prominence = 'normal'
      @incoming_message.save!
      expect(@info_request.get_last_public_response_event).to eq(@incoming_message.response_event)
    end

  end

  describe 'keeping track of the last public response date' do

    let(:old_date) { Time.zone.now - 21.days }
    let(:recent_date) { Time.zone.now - 2.days }
    let(:user) { FactoryGirl.create(:user) }

    it 'does not set last_public_response_at date if there is no response' do
      request = FactoryGirl.create(:info_request)
      expect(request.last_public_response_at).to be_nil
    end

    it 'sets last_public_response_at when a public response is added' do
      request = FactoryGirl.create(:info_request, :user => user,
                                                  :created_at => old_date)
      message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                      :info_request => request)
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message,
                                              :created_at => old_date,
                                              :event_type => 'response')
      expect(request.last_public_response_at).to eq(old_date)
    end

    it 'does not set last_public_response_at when a hidden response is added' do
      request = FactoryGirl.create(:info_request, :user => user,
                                                  :created_at => old_date)
      message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                      :info_request => request,
                                                      :prominence => 'hidden')
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message,
                                              :created_at => old_date,
                                              :event_type => 'response')
      expect(request.last_public_response_at).to be_nil
    end

    it 'sets last_public_response_at to nil when the only response is hidden' do
      request = FactoryGirl.create(:info_request, :user => user,
                                                  :created_at => old_date)
      message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                      :info_request => request)
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message,
                                              :created_at => old_date,
                                              :event_type => 'response')
      message.prominence = 'hidden'
      message.save
      expect(request.last_public_response_at).to be_nil
    end

    it 'reverts last_public_response_at when the latest response is hidden' do
      request = FactoryGirl.create(:info_request, :user => user,
                                                  :created_at => old_date)
      message1 = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                       :info_request => request)
      message2 = FactoryGirl.create(:incoming_message, :created_at => recent_date,
                                                       :info_request => request)
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message1,
                                              :created_at => old_date,
                                              :event_type => 'response')
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message2,
                                              :created_at => recent_date,
                                              :event_type => 'response')
      expect(request.last_public_response_at).to eq(recent_date)
      message2.prominence = 'hidden'
      message2.save
      expect(request.last_public_response_at).to eq(old_date)
    end

    it 'sets last_public_response_at to nil when the only response is destroyed' do
      request = FactoryGirl.create(:info_request, :user => user,
                                                  :created_at => old_date)
      message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                      :info_request => request)
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message,
                                              :created_at => old_date,
                                              :event_type => 'response')
      message.destroy
      expect(request.last_public_response_at).to be_nil
    end

    it 'reverts last_public_response_at when the latest response is destroyed' do
      request = FactoryGirl.create(:info_request, :user => user,
                                                  :created_at => old_date)
      message1 = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                       :info_request => request)
      message2 = FactoryGirl.create(:incoming_message, :created_at => recent_date,
                                                       :info_request => request)
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message1,
                                              :created_at => old_date,
                                              :event_type => 'response')
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message2,
                                              :created_at => recent_date,
                                              :event_type => 'response')
      expect(request.last_public_response_at).to eq(recent_date)
      message2.destroy
      expect(request.last_public_response_at).to eq(old_date)
    end

    it 'sets last_public_response_at when a hidden response is unhidden' do
      request = FactoryGirl.create(:info_request, :user => user,
                                                  :created_at => old_date)
      message = FactoryGirl.create(:incoming_message, :created_at => old_date,
                                                      :info_request => request,
                                                      :prominence => 'hidden')
      FactoryGirl.create(:info_request_event, :info_request => request,
                                              :incoming_message => message,
                                              :created_at => old_date,
                                              :event_type => 'response')
      message.prominence = 'normal'
      message.save
      expect(request.last_public_response_at).to eq(old_date)
    end

  end

  describe 'when asked for the last public outgoing event' do

    before do
      @info_request = FactoryGirl.create(:info_request)
      @outgoing_message = @info_request.outgoing_messages.first
    end

    it 'does not return an event with a hidden prominence message' do
      @outgoing_message.prominence = 'hidden'
      @outgoing_message.save!
      expect(@info_request.get_last_public_outgoing_event).to eq(nil)
    end

    it 'does not return an event with a requester_only prominence message' do
      @outgoing_message.prominence = 'requester_only'
      @outgoing_message.save!
      expect(@info_request.get_last_public_outgoing_event).to eq(nil)
    end

    it 'returns an event with a normal prominence message' do
      @outgoing_message.prominence = 'normal'
      @outgoing_message.save!
      expect(@info_request.get_last_public_outgoing_event).to eq(@outgoing_message.info_request_events.first)
    end

  end

  describe 'when asked who can be sent a followup' do

    before do
      @info_request = FactoryGirl.create(:info_request_with_plain_incoming)
      @incoming_message = @info_request.incoming_messages.first
      @public_body = @info_request.public_body
    end

    it 'does not include details from a hidden prominence response' do
      @incoming_message.prominence = 'hidden'
      @incoming_message.save!
      expect(@info_request.who_can_followup_to).to eq([[@public_body.name,
                                                    @public_body.request_email,
                                                    nil]])
    end

    it 'does not include details from a requester_only prominence response' do
      @incoming_message.prominence = 'requester_only'
      @incoming_message.save!
      expect(@info_request.who_can_followup_to).to eq([[@public_body.name,
                                                    @public_body.request_email,
                                                    nil]])
    end

    it 'includes details from a normal prominence response' do
      @incoming_message.prominence = 'normal'
      @incoming_message.save!
      expect(@info_request.who_can_followup_to).to eq([[@public_body.name,
                                                    @public_body.request_email,
                                                    nil],
                                                   ['Bob Responder',
                                                    "bob@example.com",
                                                    @incoming_message.id]])
    end

  end

  describe  'when generating json for the api' do

    before do
      @user = mock_model(User, :json_for_api => { :id => 20,
                                                  :url_name => 'alaveteli_user',
                                                  :name => 'Alaveteli User',
                                                  :ban_text => '',
                                                  :about_me => 'Hi' })
    end

    it 'returns full user info for an internal request' do
      @info_request = InfoRequest.new(:user => @user)
      expect(@info_request.user_json_for_api).to eq({ :id => 20,
                                                  :url_name => 'alaveteli_user',
                                                  :name => 'Alaveteli User',
                                                  :ban_text => '',
                                                  :about_me => 'Hi' })
    end

  end

  describe 'when working out a subject for request emails' do

    it 'creates a standard request subject' do
      info_request = FactoryGirl.build(:info_request)
      expected_text = "Freedom of Information request - #{info_request.title}"
      expect(info_request.email_subject_request).to eq(expected_text)
    end

  end

  describe 'when working out a subject for a followup emails' do

    it "is not confused by an nil subject in the incoming message" do
      ir = info_requests(:fancy_dog_request)
      im = mock_model(IncomingMessage,
                      :subject => nil,
                      :valid_to_reply_to? => true)
      subject = ir.email_subject_followup(:incoming_message => im, :html => false)
      expect(subject).to match(/^Re: Freedom of Information request.*fancy dog/)
    end

    it "returns a hash with the user's name for an external request" do
      @info_request = InfoRequest.new(:external_url => 'http://www.example.com',
                                      :external_user_name => 'External User')
      expect(@info_request.user_json_for_api).to eq({:name => 'External User'})
    end

    it 'returns "Anonymous user" for an anonymous external user' do
      @info_request = InfoRequest.new(:external_url => 'http://www.example.com')
      expect(@info_request.user_json_for_api).to eq({:name => 'Anonymous user'})
    end

  end

  describe "#set_described_state and #log_event" do

    context "a request" do

      let(:request) { InfoRequest.create!(:title => "my request",
                                          :public_body => public_bodies(:geraldine_public_body),
                                          :user => users(:bob_smith_user)) }

      context "a series of events on a request" do

        it "has sensible events after the initial request has been made" do
          # An initial request is sent
          # FIXME: The logic that changes the status when a message
          # is sent is mixed up in
          # OutgoingMessage#record_email_delivery. So, rather than
          # extract it (or call it) let's just duplicate what it does
          # here for the time being.
          request.log_event('sent', {})
          request.set_described_state('waiting_response')

          events = request.info_request_events
          expect(events.count).to eq(1)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
        end

        it "has sensible events after a response is received to a request" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # A response is received
          # This is normally done in InfoRequest#receive
          request.awaiting_description = true
          request.log_event("response", {})

          events = request.info_request_events
          expect(events.count).to eq(2)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("response")
          expect(events[1].described_state).to be_nil
          # TODO: Should calculated_status in this situation be "waiting_classification"?
          # This would allow searches like "latest_status: waiting_classification" to be
          # available to the user in "Advanced search"
          expect(events[1].calculated_state).to be_nil
        end

        it "has sensible events after a request is classified by the requesting user" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # A response is received
          request.awaiting_description = true
          request.log_event("response", {})
          # The request is classified by the requesting user
          # This is normally done in RequestController#describe_state
          request.log_event("status_update", {})
          request.set_described_state("waiting_response")

          events = request.info_request_events
          expect(events.count).to eq(3)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("response")
          expect(events[1].described_state).to be_nil
          expect(events[1].calculated_state).to eq('waiting_response')
          expect(events[2].event_type).to eq("status_update")
          expect(events[2].described_state).to eq("waiting_response")
          expect(events[2].calculated_state).to eq("waiting_response")
        end

        it "has sensible events after a normal followup is sent" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # A response is received
          request.awaiting_description = true
          request.log_event("response", {})
          # The request is classified by the requesting user
          request.log_event("status_update", {})
          request.set_described_state("waiting_response")
          # A normal follow up is sent
          # This is normally done in
          # OutgoingMessage#record_email_delivery
          request.log_event('followup_sent', {})
          request.set_described_state('waiting_response')

          events = request.info_request_events
          expect(events.count).to eq(4)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("response")
          expect(events[1].described_state).to be_nil
          expect(events[1].calculated_state).to eq('waiting_response')
          expect(events[2].event_type).to eq("status_update")
          expect(events[2].described_state).to eq("waiting_response")
          expect(events[2].calculated_state).to eq("waiting_response")
          expect(events[3].event_type).to eq("followup_sent")
          expect(events[3].described_state).to eq("waiting_response")
          expect(events[3].calculated_state).to eq("waiting_response")
        end

        it "has sensible events after a user classifies the request after a follow up" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # A response is received
          request.awaiting_description = true
          request.log_event("response", {})
          # The request is classified by the requesting user
          request.log_event("status_update", {})
          request.set_described_state("waiting_response")
          # A normal follow up is sent
          request.log_event('followup_sent', {})
          request.set_described_state('waiting_response')
          # The request is classified by the requesting user
          request.log_event("status_update", {})
          request.set_described_state("waiting_response")

          events = request.info_request_events
          expect(events.count).to eq(5)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("response")
          expect(events[1].described_state).to be_nil
          expect(events[1].calculated_state).to eq('waiting_response')
          expect(events[2].event_type).to eq("status_update")
          expect(events[2].described_state).to eq("waiting_response")
          expect(events[2].calculated_state).to eq("waiting_response")
          expect(events[3].event_type).to eq("followup_sent")
          expect(events[3].described_state).to eq("waiting_response")
          expect(events[3].calculated_state).to eq("waiting_response")
          expect(events[4].event_type).to eq("status_update")
          expect(events[4].described_state).to eq("waiting_response")
          expect(events[4].calculated_state).to eq("waiting_response")
        end

      end

      context "another series of events on a request" do

        it "has sensible event states" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # An internal review is requested
          request.log_event('followup_sent', {})
          request.set_described_state('internal_review')

          events = request.info_request_events
          expect(events.count).to eq(2)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("followup_sent")
          expect(events[1].described_state).to eq("internal_review")
          expect(events[1].calculated_state).to eq("internal_review")
        end

        it "has sensible event states" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # An internal review is requested
          request.log_event('followup_sent', {})
          request.set_described_state('internal_review')
          # The user marks the request as rejected
          request.log_event("status_update", {})
          request.set_described_state("rejected")

          events = request.info_request_events
          expect(events.count).to eq(3)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("followup_sent")
          expect(events[1].described_state).to eq("internal_review")
          expect(events[1].calculated_state).to eq("internal_review")
          expect(events[2].event_type).to eq("status_update")
          expect(events[2].described_state).to eq("rejected")
          expect(events[2].calculated_state).to eq("rejected")
        end

      end

      context "another series of events on a request" do

        it "has sensible event states" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # The user marks the request as successful (I know silly but someone did
          # this in https://www.whatdotheyknow.com/request/family_support_worker_redundanci)
          request.log_event("status_update", {})
          request.set_described_state("successful")

          events = request.info_request_events
          expect(events.count).to eq(2)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("status_update")
          expect(events[1].described_state).to eq("successful")
          expect(events[1].calculated_state).to eq("successful")
        end

        it "has sensible event states" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')

          # A response is received
          request.awaiting_description = true
          request.log_event("response", {})

          # The user marks the request as successful
          request.log_event("status_update", {})
          request.set_described_state("successful")

          events = request.info_request_events
          expect(events.count).to eq(3)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("response")
          expect(events[1].described_state).to be_nil
          expect(events[1].calculated_state).to eq("successful")
          expect(events[2].event_type).to eq("status_update")
          expect(events[2].described_state).to eq("successful")
          expect(events[2].calculated_state).to eq("successful")
        end

      end

      context "another series of events on a request" do

        it "has sensible event states" do
          # An initial request is sent
          request.log_event('sent', {})
          request.set_described_state('waiting_response')
          # An admin sets the status of the request to 'gone postal' using
          # the admin interface
          request.log_event("edit", {})
          request.set_described_state("gone_postal")

          events = request.info_request_events
          expect(events.count).to eq(2)
          expect(events[0].event_type).to eq("sent")
          expect(events[0].described_state).to eq("waiting_response")
          expect(events[0].calculated_state).to eq("waiting_response")
          expect(events[1].event_type).to eq("edit")
          expect(events[1].described_state).to eq("gone_postal")
          expect(events[1].calculated_state).to eq("gone_postal")
        end

      end

    end

  end

  describe 'when saving an info_request' do

    before do
      @info_request = InfoRequest.new(:external_url => 'http://www.example.com',
                                      :external_user_name => 'Example User',
                                      :title => 'Some request or other',
                                      :public_body => public_bodies(:geraldine_public_body))
    end

    it "calls purge_in_cache and update_counter_cache" do
      # Twice - once for save, once for destroy:
      expect(@info_request).to receive(:purge_in_cache).twice
      expect(@info_request).to receive(:update_counter_cache).twice
      @info_request.save!
      @info_request.destroy
    end

  end

  describe 'when changing a described_state' do

    it "changes the counts on its PublicBody without saving a new version" do
      pb = public_bodies(:geraldine_public_body)
      old_version_count = pb.versions.count
      old_successful_count = pb.info_requests_successful_count
      old_not_held_count = pb.info_requests_not_held_count
      old_visible_count = pb.info_requests_visible_count
      ir = InfoRequest.new(:external_url => 'http://www.example.com',
                           :external_user_name => 'Example User',
                           :title => 'Some request or other',
                           :described_state => 'partially_successful',
                           :public_body => pb)
      ir.save!
      expect(pb.info_requests_successful_count).to eq(old_successful_count + 1)
      expect(pb.info_requests_visible_count).to eq(old_visible_count + 1)
      ir.described_state = 'not_held'
      ir.save!
      pb.reload
      expect(pb.info_requests_successful_count).to eq(old_successful_count)
      expect(pb.info_requests_not_held_count).to eq(old_not_held_count + 1)
      ir.described_state = 'successful'
      ir.save!
      pb.reload
      expect(pb.info_requests_successful_count).to eq(old_successful_count + 1)
      expect(pb.info_requests_not_held_count).to eq(old_not_held_count)
      ir.destroy
      pb.reload
      expect(pb.info_requests_successful_count).to eq(old_successful_count)
      expect(pb.info_requests_successful_count).to eq(old_not_held_count)
      expect(pb.info_requests_visible_count).to eq(old_visible_count)
      expect(pb.versions.count).to eq(old_version_count)
    end

  end

  describe 'when changing prominence' do

    it "changes the counts on its PublicBody without saving a new version" do
      pb = public_bodies(:geraldine_public_body)
      old_version_count = pb.versions.count
      old_successful_count = pb.info_requests_successful_count
      old_not_held_count = pb.info_requests_not_held_count
      old_visible_count = pb.info_requests_visible_count
      ir = InfoRequest.new(:external_url => 'http://www.example.com',
                           :external_user_name => 'Example User',
                           :title => 'Some request or other',
                           :described_state => 'partially_successful',
                           :public_body => pb)
      ir.save!
      expect(pb.info_requests_successful_count).to eq(old_successful_count + 1)
      expect(pb.info_requests_visible_count).to eq(old_visible_count + 1)
      ir.prominence = 'hidden'
      ir.save!
      pb.reload
      expect(pb.info_requests_successful_count).to eq(old_successful_count)
      expect(pb.info_requests_not_held_count).to eq(old_not_held_count)
      expect(pb.info_requests_visible_count).to eq(old_visible_count)

      ir.prominence = 'normal'
      ir.save!
      pb.reload
      expect(pb.info_requests_successful_count).to eq(old_successful_count + 1)
      expect(pb.info_requests_not_held_count).to eq(old_not_held_count)
      expect(pb.info_requests_visible_count).to eq(old_visible_count + 1)
      ir.destroy
      pb.reload
      expect(pb.info_requests_successful_count).to eq(old_successful_count)
      expect(pb.info_requests_successful_count).to eq(old_not_held_count)
      expect(pb.info_requests_visible_count).to eq(old_visible_count)
      expect(pb.versions.count).to eq(old_version_count)
    end

  end

  describe InfoRequest, 'when getting similar requests' do

    before(:each) do
      get_fixtures_xapian_index
    end

    it 'returns similar requests' do
      similar, more = info_requests(:spam_1_request).similar_requests(1)
      expect(similar.results.first[:model].info_request).to eq(info_requests(:spam_2_request))
    end

    it 'returns a flag set to true' do
      similar, more = info_requests(:spam_1_request).similar_requests(1)
      expect(more).to be true
    end

  end

  describe InfoRequest, 'when constructing the list of recent requests' do

    before(:each) do
      get_fixtures_xapian_index
    end

    describe 'when there are fewer than five successful requests' do

      it 'lists the most recently sent and successful requests by the creation
                date of the request event' do
        # Make sure the newest response is listed first even if a request
        # with an older response has a newer comment or was reclassified more recently:
        # https://github.com/mysociety/alaveteli/issues/370
        #
        # This is a deliberate behaviour change, in that the
        # previous behaviour (showing more-recently-reclassified
        # requests first) was intentional.
        request_events, request_events_all_successful = InfoRequest.recent_requests
        previous = nil
        request_events.each do |event|
          if previous
            expect(previous.created_at).to be >= event.created_at
          end
          expect(['sent', 'response'].include?(event.event_type)).to be true
          if event.event_type == 'response'
            expect(['successful', 'partially_successful'].include?(event.calculated_state)).to be true
          end
          previous = event
        end

      end

    end

    it 'coalesces duplicate requests' do
      request_events, request_events_all_successful = InfoRequest.recent_requests
      expect(request_events.map(&:info_request).select{|x|x.url_title =~ /^spam/}.length).to eq(1)
    end

  end

  describe InfoRequest, "when constructing a list of requests by query" do

    before(:each) do
      load_raw_emails_data
      get_fixtures_xapian_index
    end

    def apply_filters(filters)
      results = InfoRequest.request_list(filters, page=1, per_page=100, max_results=100)
      results[:results].map(&:info_request)
    end

    it "filters requests" do
      expect(apply_filters(:latest_status => 'all')).to match_array(InfoRequest.all)

      # default sort order is the request with the most recently created event first
      expect(apply_filters(:latest_status => 'all')).to eq(InfoRequest.all(
        :order => "(SELECT max(info_request_events.created_at)
                            FROM info_request_events
                            WHERE info_request_events.info_request_id = info_requests.id)
                            DESC"))

      expect(apply_filters(:latest_status => 'successful')).to match_array(InfoRequest.all(
        :conditions => "id in (
                    SELECT info_request_id
                    FROM info_request_events
                    WHERE NOT EXISTS (
                        SELECT *
                        FROM info_request_events later_events
                        WHERE later_events.created_at > info_request_events.created_at
                        AND later_events.info_request_id = info_request_events.info_request_id
                        AND later_events.described_state IS NOT null
                    )
                    AND info_request_events.described_state IN ('successful', 'partially_successful')
                )"))
    end

    it "filters requests by date" do
      # The semantics of the search are that it finds any InfoRequest
      # that has any InfoRequestEvent created in the specified range
      filters = {:latest_status => 'all', :request_date_before => '13/10/2007'}
      expect(apply_filters(filters)).to match_array(InfoRequest.all(
        :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE created_at < '2007-10-13'::date)"))

      filters = {:latest_status => 'all', :request_date_after => '13/10/2007'}
      expect(apply_filters(filters)).to match_array(InfoRequest.all(
        :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE created_at > '2007-10-13'::date)"))

      filters = {:latest_status => 'all',
                 :request_date_after => '13/10/2007',
                 :request_date_before => '01/11/2007'}
      expect(apply_filters(filters)).to match_array(InfoRequest.all(
        :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE created_at BETWEEN '2007-10-13'::date
                                       AND '2007-11-01'::date)"))
    end

    it "lists internal_review requests as unresolved ones" do
      # This doesn’t precisely duplicate the logic of the actual
      # query, but it is close enough to give the same result with
      # the current set of test data.
      results = apply_filters(:latest_status => 'awaiting')
      expect(results).to match_array(InfoRequest.all(
        :conditions => "id IN (SELECT info_request_id
                                       FROM info_request_events
                                       WHERE described_state in (
                        'waiting_response', 'waiting_clarification',
                        'internal_review', 'gone_postal', 'error_message', 'requires_admin'
                    ) and not exists (
                        select *
                        from info_request_events later_events
                        where later_events.created_at > info_request_events.created_at
                        and later_events.info_request_id = info_request_events.info_request_id
                    ))"))

      expect(results.include?(info_requests(:fancy_dog_request))).to eq(false)

      event = info_request_events(:useless_incoming_message_event)
      event.described_state = event.calculated_state = "internal_review"
      event.save!
      rebuild_xapian_index
      results = apply_filters(:latest_status => 'awaiting')
      expect(results.include?(info_requests(:fancy_dog_request))).to eq(true)
    end

  end

  def email_and_raw_email(opts = {})
    raw_email = opts[:raw_email] || <<-EOF.strip_heredoc
    From: EMAIL_FROM
    To: EMAIL_TO
    Subject: Basic Email
    Hello, World
    EOF

    email_to = opts[:to] || 'to@example.org'
    email_from = opts[:from] || 'from@example.com'

    raw_email.gsub!('EMAIL_TO', email_to)
    raw_email.gsub!('EMAIL_FROM', email_from)

    email = MailHandler.mail_from_raw_email(raw_email)
    [email, raw_email]
  end

end
