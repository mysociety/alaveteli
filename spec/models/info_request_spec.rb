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
#  reject_incoming_at_mta    :boolean          default(FALSE), not null
#  rejected_incoming_count   :integer          default(0)
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe InfoRequest do

  describe 'creating a new request' do

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

    it "sets the url_title from the supplied title" do
      info_request = FactoryGirl.create(:info_request, :title => "Test title")
      expect(info_request.url_title).to eq("test_title")
    end

    it "ignores any supplied url_title and sets it from the title instead" do
      info_request = FactoryGirl.create(:info_request, :title => "Real title",
                                                       :url_title => "ignore_me")
      expect(info_request.url_title).to eq("real_title")
    end

    it "adds the next sequential number to the url_title to make it unique" do
      allow(InfoRequest).to receive(:find_by_url_title).
        with("test_title", :conditions => nil).
          and_return(mock_model(InfoRequest))
      allow(InfoRequest).to receive(:find_by_url_title).
        with("test_title_2", :conditions => nil).
          and_return(mock_model(InfoRequest))

      # not found - we can use this one
      allow(InfoRequest).to receive(:find_by_url_title).
        with("test_title_3", :conditions => nil).
          and_return(nil)

      info_request = InfoRequest.new(:title => "Test title")
      expect(info_request.url_title).to eq("test_title_3")
    end

    context "when a race condition creates a duplicate between new and save" do
      # this appears to be happening in the request#new controller method
      # we suspect (hope?) it's an accidental double press of 'Save'

      it "picks the next available url_title instead of failing" do
        public_body = FactoryGirl.create(:public_body)
        user = FactoryGirl.create(:user)
        first_request = InfoRequest.new(:title => "Test title",
                                        :user => user,
                                        :public_body => public_body)
        second_request = FactoryGirl.create(:info_request, :title => "Test title")
        first_request.save!
        expect(first_request.url_title).to eq("test_title_2")
      end

    end

  end

  describe '.holding_pen_request' do

    context 'when the holding pen exists' do

      it 'finds a request with title "Holding pen"' do
        holding_pen = FactoryGirl.create(:info_request, :title => 'Holding pen')
        expect(InfoRequest.holding_pen_request).to eq(holding_pen)
      end

    end

    context 'when no holding pen exists' do

      before do
        InfoRequest.where(:title => 'Holding pen').destroy_all
        @holding_pen = InfoRequest.holding_pen_request
      end

      it 'creates a holding pen request' do
        expect(@holding_pen.title).to eq('Holding pen')
      end

      it 'creates the holding pen as hidden' do
        expect(@holding_pen.prominence).to eq('hidden')
      end

      it 'creates the holding pen to the internal admin body' do
        expect(@holding_pen.public_body).to eq(PublicBody.internal_admin_body)
      end

      it 'creates the holding pen from the internal admin user' do
        expect(@holding_pen.user).to eq(User.internal_admin_user)
      end

      it 'sets a message on the holding pen' do
        expected_message = 'This is the holding pen request. It shows ' \
                           'responses that were sent to invalid addresses, ' \
                           'and need moving to the correct request by an ' \
                           'adminstrator.'
        expect(@holding_pen.outgoing_messages.first.body).
          to eq(expected_message)
      end

    end

  end

  describe '.reject_incoming_at_mta' do

    before do
      @request = FactoryGirl.create(:info_request)
      @request.update_attributes(:updated_at => 6.months.ago,
                                :rejected_incoming_count => 3,
                                :allow_new_responses_from => 'nobody')
      @options = {:rejection_threshold => 2,
                  :age_in_months => 5,
                  :dryrun => true}
    end

    it 'returns an count of requests updated ' do
      expect(InfoRequest.reject_incoming_at_mta(@options.merge(:dryrun => false))).
        to eq(1)
    end

    it 'does nothing on a dryrun' do
      InfoRequest.reject_incoming_at_mta(@options)
      expect(InfoRequest.find(@request.id).reject_incoming_at_mta).to be false
    end

    it 'sets reject_incoming_at_mta on a request meeting the criteria passed' do
      InfoRequest.reject_incoming_at_mta(@options.merge(:dryrun => false))
      expect(InfoRequest.find(@request.id).reject_incoming_at_mta).to be true
    end

    it 'does not set reject_incoming_at_mta on a request not meeting the
        criteria passed' do
      InfoRequest.reject_incoming_at_mta(@options.merge(:dryrun => false,
                                                        :age_in_months => 7))
      expect(InfoRequest.find(@request.id).reject_incoming_at_mta).to be false
    end

    it 'yields an array of ids of the requests matching the criteria' do
      InfoRequest.reject_incoming_at_mta(@options) do |ids|
        expect(ids).to eq([@request.id])
      end
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
        updated_at = info_request.updated_at = 5.days.ago
        info_request.save!
        email, raw_email = email_and_raw_email
        info_request.receive(email, raw_email)
        holding_pen = InfoRequest.holding_pen_request
        msg = 'This request has been set by an administrator to "allow new ' \
              'responses from nobody"'
        expect(info_request.incoming_messages.size).to eq(0)
        expect(holding_pen.incoming_messages.size).to eq(1)
        expect(holding_pen.info_request_events.last.params[:rejected_reason]).
          to eq(msg)
        expect(info_request.reload.rejected_incoming_count).to eq(1)
        expect(info_request.reload.updated_at).to eq(updated_at)
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
        updated_at = info_request.updated_at = 5.days.ago
        info_request.save!
        email, raw_email = email_and_raw_email(:from => '')
        info_request.receive(email, raw_email)
        expect(info_request.reload.incoming_messages.size).to eq(0)
        holding_pen = InfoRequest.holding_pen_request
        expect(holding_pen.incoming_messages.size).to eq(1)
        msg = 'Only the authority can reply to this request, but there is ' \
              'no "From" address to check against'
        expect(holding_pen.info_request_events.last.params[:rejected_reason]).
          to eq(msg)
        expect(info_request.rejected_incoming_count).to eq(1)
        expect(info_request.reload.updated_at).to eq(updated_at)
      end

      it 'from authority_only rejects if the mail is not from the authority' do
        attrs = { :allow_new_responses_from => 'authority_only',
                  :handle_rejected_responses => 'holding_pen' }
        info_request = FactoryGirl.create(:info_request, attrs)
        updated_at = info_request.updated_at = 5.days.ago
        info_request.save!
        email, raw_email = email_and_raw_email(:from => 'spam@example.net')
        info_request.receive(email, raw_email)
        expect(info_request.reload.incoming_messages.size).to eq(0)
        holding_pen = InfoRequest.holding_pen_request
        expect(holding_pen.incoming_messages.size).to eq(1)
        msg = "Only the authority can reply to this request, and I don't " \
              "recognise the address this reply was sent from"
        expect(holding_pen.info_request_events.last.params[:rejected_reason]).
          to eq(msg)
        expect(info_request.rejected_incoming_count).to eq(1)
        expect(info_request.reload.updated_at).to eq(updated_at)
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
      expect(info_request.reload.rejected_incoming_count).to eq(1)
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

      expect(info_request.reload.rejected_incoming_count).to eq(1)
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
      expect(info_request.reload.rejected_incoming_count).to eq(1)
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
      expect(info_request.rejected_incoming_count).to eq(0)
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
      expect(info_request.rejected_incoming_count).to eq(0)
      expect(info_request.incoming_messages.size).to eq(1)
      ActionMailer::Base.deliveries.clear
    end

  end

  describe "#url_title" do
    let(:request) { FactoryGirl.create(:info_request, :title => "Test 101") }

    it "returns the url_title" do
      expect(request.url_title).to eq('test_101')
    end

    it "collapses the url title if requested" do
      expect(request.url_title(:collapse => true)).to eq("test")
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

  describe '#expire' do

    let(:info_request) { FactoryGirl.create(:info_request) }

    it "clears the database caches" do
      expect(info_request).to receive(:clear_in_database_caches!)
      info_request.expire
    end

    it "does not clear the database caches if passed the preserve_database_cache option" do
      expect(info_request).not_to receive(:clear_in_database_caches!)
      info_request.expire(:preserve_database_cache => true)
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

  describe '.find_existing' do

    it 'returns a request with the params given' do
      info_request = FactoryGirl.create(:info_request)
      expect(InfoRequest.find_existing(info_request.title,
                                       info_request.public_body_id,
                                       'Some information please')).
        to eq(info_request)
    end

  end

  describe '#find_existing_outgoing_message' do

    it 'returns an outgoing message with the body text given' do
      info_request = FactoryGirl.create(:info_request)
      expect(info_request.find_existing_outgoing_message('Some information please')).
        to eq(info_request.outgoing_messages.first)
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

  describe '#late_calculator' do

    it 'returns a DefaultLateCalculator' do
      expect(subject.late_calculator).
        to be_instance_of(DefaultLateCalculator)
    end

    it 'caches the late calculator' do
      expect(subject.late_calculator).to equal(subject.late_calculator)
    end

  end

  describe "#is_followupable?" do

    let(:message_without_reply_to) { FactoryGirl.create(:incoming_message) }
    let(:valid_request) { FactoryGirl.create(:info_request) }
    let(:unfollowupable_body) { FactoryGirl.create(:public_body, :request_email => "") }

    context "it is possible to reply to the public body" do

      it "returns true" do
        expect(valid_request.is_followupable?(message_without_reply_to)).
          to eq(true)
      end

      it "should not set a followup_bad_reason" do
        valid_request.is_followupable?(message_without_reply_to)
        expect(valid_request.followup_bad_reason).to be_nil
      end

    end


    context "the message has a valid reply address" do

      let(:request) do
        FactoryGirl.create(:info_request, :public_body => unfollowupable_body)
      end
      let(:dummy_message) { double(IncomingMessage) }

      before do
        allow(dummy_message).to receive(:valid_to_reply_to?) { true }
      end

      it "returns true" do
        expect(request.is_followupable?(dummy_message)).to eq(true)
      end

      it "should not set a followup_bad_reason" do
        request.is_followupable?(dummy_message)
        expect(request.followup_bad_reason).to be_nil
      end

    end

    context "an external request" do

      let(:info_request) { InfoRequest.new(:external_url => "demo_url") }

      it "returns false" do
        expect(info_request.is_followupable?(message_without_reply_to)).
          to eq(false)
      end

      it "sets followup_bad_reason to 'external'" do
        info_request.is_followupable?(message_without_reply_to)
        expect(info_request.followup_bad_reason).to eq("external")
      end

    end

    context "belongs to an unfollowupable PublicBody" do

      let(:request) do
        FactoryGirl.create(:info_request, :public_body => unfollowupable_body)
      end

      it "returns false" do
        expect(request.is_followupable?(message_without_reply_to)).to eq(false)
      end

      it "sets followup_bad_reason to the public body's not_requestable_reason" do
        request.is_followupable?(message_without_reply_to)
        expect(request.followup_bad_reason).
          to eq(unfollowupable_body.not_requestable_reason)
      end

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

    it 'rejects an invalid prominence' do
      info_request = InfoRequest.new(:prominence => 'something')
      info_request.valid?
      expect(info_request.errors[:prominence]).to include("is not included in the list")
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
      IncomingMessage.find_each{ |message| message.parse_raw_email! }
      rebuild_xapian_index
      # delete event from underneath indexing; shouldn't cause error
      info_request_events(:useless_incoming_message_event).save!
      info_request_events(:useless_incoming_message_event).destroy
      update_xapian_index
    end

  end

  describe "#postal_email" do

    let(:public_body) do
      FactoryGirl.create(:public_body, :request_email => "test@localhost")
    end

    context "there is no list of incoming messages to followup" do

      it "returns the public body's request_email" do
        request = FactoryGirl.create(:info_request, :public_body => public_body)
        expect(request.postal_email).to eq("test@localhost")
      end

    end

    context "there is a list of incoming messages to followup" do

      it "returns the email address from the last message in the chain" do
        request = FactoryGirl.create(:info_request, :public_body => public_body)
        incoming_message = FactoryGirl.create(:plain_incoming_message,
                                              :info_request => request)
        request.log_event("response", {:incoming_message_id => incoming_message.id})
        expect(request.postal_email).to eq("bob@example.com")
      end

    end

  end

  describe "#postal_email_name" do

    let(:public_body) { FactoryGirl.create(:public_body, :name => "Ministry of Test") }

    context "there is no list of incoming messages to followup" do

      it "returns the public body name" do
        request = FactoryGirl.create(:info_request, :public_body => public_body)
        expect(request.postal_email_name).to eq("Ministry of Test")
      end

    end

    context "there is a list of incoming messages to followup" do

      it "returns the email name from the last message in the chain" do
        request = FactoryGirl.create(:info_request, :public_body => public_body)
        incoming_message = FactoryGirl.create(:plain_incoming_message,
                                              :info_request => request)
        request.log_event("response", {:incoming_message_id => incoming_message.id})
        expect(request.postal_email_name).to eq("Bob Responder")
      end

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
                                                    :title => 'Holding pen',
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
        results = InfoRequest.where_old_unclassified
        expect(results).to include(old_unclassified_request)
      end

      it "does not return records less than 21 days old" do
        recent_unclassified_request = create_recent_unclassified_request
        results = InfoRequest.where_old_unclassified
        expect(results).not_to include(recent_unclassified_request)
      end

      it "only returns records with an associated user" do
        old_unclassified_no_user = create_old_unclassified_no_user
        results = InfoRequest.where_old_unclassified
        expect(results).not_to include(old_unclassified_no_user)
      end

      it "only returns records which are awaiting description" do
        old_unclassified_described = create_old_unclassified_described
        results = InfoRequest.where_old_unclassified
        expect(results).not_to include(old_unclassified_described)
      end

      it "does not return anything which is in the holding pen" do
        old_unclassified_holding_pen = create_old_unclassified_holding_pen
        results = InfoRequest.where_old_unclassified
        expect(results).not_to include(old_unclassified_holding_pen)
      end
    end

  end

  describe 'when asked for random old unclassified requests with normal prominence' do

    it "does not return requests that don't have normal prominence" do
      dog_request = info_requests(:fancy_dog_request)
      old_unclassified =
        InfoRequest.where_old_unclassified.
          where(:prominence => 'normal').limit(1).order('random()')
      expect(old_unclassified.length).to eq(1)
      expect(old_unclassified.first).to eq(dog_request)
      dog_request.prominence = 'requester_only'
      dog_request.save!
      old_unclassified =
        InfoRequest.where_old_unclassified.
          where(:prominence => 'normal').limit(1).order('random()')
      expect(old_unclassified.length).to eq(0)
      dog_request.prominence = 'hidden'
      dog_request.save!
      old_unclassified =
        InfoRequest.where_old_unclassified.
          where(:prominence => 'normal').limit(1).order('random()')
      expect(old_unclassified.length).to eq(0)
    end

  end

  describe 'when asked to count old unclassified requests with normal prominence' do

    it "does not return requests that don't have normal prominence" do
      dog_request = info_requests(:fancy_dog_request)
      old_unclassified = InfoRequest.where_old_unclassified.
        where(:prominence => 'normal').count
      expect(old_unclassified).to eq(1)
      dog_request.prominence = 'requester_only'
      dog_request.save!
      old_unclassified = InfoRequest.where_old_unclassified.
        where(:prominence => 'normal').count
      expect(old_unclassified).to eq(0)
      dog_request.prominence = 'hidden'
      dog_request.save!
      old_unclassified = InfoRequest.where_old_unclassified.
        where(:prominence => 'normal').count
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

  describe '#apply_censor_rules_to_text' do

    it 'applies each censor rule to the text' do
      rule_1 = FactoryGirl.build(:censor_rule, :text => '1')
      rule_2 = FactoryGirl.build(:censor_rule, :text => '2')
      info_request = FactoryGirl.build(:info_request)
      allow(info_request).
        to receive(:applicable_censor_rules).and_return([rule_1, rule_2])

      expected = '[REDACTED] 3 [REDACTED]'

      expect(info_request.apply_censor_rules_to_text('1 3 2')).to eq(expected)
    end

  end

  describe '#apply_censor_rules_to_binary' do

    it 'applies each censor rule to the text' do
      rule_1 = FactoryGirl.build(:censor_rule, :text => '1')
      rule_2 = FactoryGirl.build(:censor_rule, :text => '2')
      info_request = FactoryGirl.build(:info_request)
      allow(info_request).
        to receive(:applicable_censor_rules).and_return([rule_1, rule_2])

      text = '1 3 2'
      text.force_encoding('ASCII-8BIT') if String.method_defined?(:encode)

      expect(info_request.apply_censor_rules_to_binary(text)).to eq('x 3 x')
    end

  end

  describe '#apply_masks' do

    before(:each) do
      @request = FactoryGirl.create(:info_request)

      @default_opts = { :last_edit_editor => 'unknown',
                        :last_edit_comment => 'none' }
    end

    it 'replaces text with global censor rules' do
      data = 'There was a mouse called Stilton, he wished that he was blue'
      expected = 'There was a mouse called Stilton, he said that he was blue'

      opts = { :text => 'wished',
               :replacement => 'said' }.merge(@default_opts)
      CensorRule.create!(opts)

      result = @request.apply_masks(data, 'text/plain')

      expect(result).to eq(expected)
    end

    it 'replaces text with censor rules belonging to the info request' do
      data = 'There was a mouse called Stilton.'
      expected = 'There was a cat called Jarlsberg.'

      rules = [
        { :text => 'Stilton', :replacement => 'Jarlsberg' },
        { :text => 'm[a-z][a-z][a-z]e', :regexp => true, :replacement => 'cat' }
      ]

      rules.each do |rule|
        @request.censor_rules << CensorRule.new(rule.merge(@default_opts))
      end

      result = @request.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text with censor rules belonging to the user' do
      data = 'There was a mouse called Stilton.'
      expected = 'There was a cat called Jarlsberg.'

      rules = [
        { :text => 'Stilton', :replacement => 'Jarlsberg' },
        { :text => 'm[a-z][a-z][a-z]e', :regexp => true, :replacement => 'cat' }
      ]

      rules.each do |rule|
        @request.user.censor_rules << CensorRule.new(rule.merge(@default_opts))
      end

      result = @request.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text with masks belonging to the info request' do
      data = "He emailed #{ @request.incoming_email }"
      expected = "He emailed [FOI ##{ @request.id } email]"
      result = @request.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text with global masks' do
      data = 'His email address was stilton@example.org'
      expected = 'His email address was [email address]'
      result = @request.apply_masks(data, 'text/plain')
      expect(result).to eq(expected)
    end

    it 'replaces text in binary files' do
      data = 'His email address was stilton@example.org'
      expected = 'His email address was xxxxxxx@xxxxxxx.xxx'
      result = @request.apply_masks(data, 'application/vnd.ms-word')
      expect(result).to eq(expected)
    end

  end

  describe '#prominence' do

    let(:info_request){ FactoryGirl.build(:info_request) }

    it 'returns the prominence of the request' do
      expect(info_request.prominence).to eq("normal")
    end

    context ':decorate option is true' do

      it 'returns a prominence calculator' do
        expect(InfoRequest.new.prominence(:decorate => true))
          .to be_a(InfoRequest::Prominence::Calculator)
      end

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

  describe "making a zip cache path for a user" do
    let(:non_owner) { FactoryGirl.create(:user) }
    let(:owner) { request.user }
    let(:admin) { FactoryGirl.create(:admin_user) }

    let(:base_path) do
      File.join(Rails.root, "cache", "zips", "test", "download", "123",
                "123456", "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
    end
    let(:path) { File.join(base_path, "test.zip") }
    let(:hidden_path) { File.join(base_path, "test_hidden.zip") }
    let(:requester_only_path) { File.join(base_path, "test_requester_only.zip") }

    # Slightly confusing - this runs *after* the let(:request) in each context
    # below, so it's ok
    before do
      # Digest::SHA1.hexdigest("test")
      test_hash = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
      allow(request).to receive(:last_update_hash).and_return(test_hash)
    end

    shared_examples_for "a situation when everything is public" do
      it "doesn't add a suffix for anyone" do
        expect(request.make_zip_cache_path(nil)).to eq (path)
        expect(request.make_zip_cache_path(non_owner)).to eq (path)
        expect(request.make_zip_cache_path(admin)).to eq (path)
        expect(request.make_zip_cache_path(owner)).to eq (path)
      end
    end

    shared_examples_for "a situation when anything is not public" do
      it "doesn't add a suffix for anonymous users" do
        expect(request.make_zip_cache_path(nil)).to eq (path)
      end

      it "doesn't add a suffix for non owner users" do
        expect(request.make_zip_cache_path(non_owner)).to eq (path)
      end

      it "adds a _hidden suffix for admin users" do
        expect(request.make_zip_cache_path(admin)).to eq (hidden_path)
      end

      it "adds a requester_only suffix for owner users" do
        expect(request.make_zip_cache_path(owner)).to eq (requester_only_path)
      end
    end

    shared_examples_for "a request when any correspondence is not public" do
      context "when an incoming message is hidden" do
        before do
          incoming = request.incoming_messages.first
          incoming.prominence = "hidden"
          incoming.save!
        end

        it_behaves_like "a situation when anything is not public"
      end

      context "when an incoming message is requester_only" do
        before do
          incoming = request.incoming_messages.first
          incoming.prominence = "requester_only"
          incoming.save!
        end

        it_behaves_like "a situation when anything is not public"
      end

      context "when an outgoing message is hidden" do
        before do
          outgoing = request.outgoing_messages.first
          outgoing.prominence = "hidden"
          outgoing.save!
        end

        it_behaves_like "a situation when anything is not public"
      end

      context "when an outgoing message is requester_only" do
        before do
          outgoing = request.outgoing_messages.first
          outgoing.prominence = "requester_only"
          outgoing.save!
        end

        it_behaves_like "a situation when anything is not public"
      end
    end

    shared_examples_for "a request when anything is not public" do
      context "when the request is not public but the correspondence is" do
        it_behaves_like "a situation when anything is not public"
      end

      context "when the request is not public and neither is the correspondence" do
        it_behaves_like "a request when any correspondence is not public"
      end
    end

    context "when the request is public" do
      let(:request) do
        FactoryGirl.create(:info_request_with_incoming, id: 123456,
                                                        title: "test")
      end

      context "when all correspondence is public" do
        it_behaves_like "a situation when everything is public"
      end

      it_behaves_like "a request when any correspondence is not public"
    end

    context "when the request is hidden" do
      let(:request) do
        FactoryGirl.create(:info_request_with_incoming, id: 123456,
                                                        title: "test",
                                                        prominence: "hidden")
      end

      it_behaves_like "a request when anything is not public"
    end

    context "when the request is requester_only" do
      let(:request) do
        FactoryGirl.create(
          :info_request_with_incoming,
          id: 123456,
          title: "test",
          prominence: "requester_only"
        )
      end

      it_behaves_like "a request when anything is not public"
    end
  end

  describe ".from_draft" do
    let(:draft) { FactoryGirl.create(:draft_info_request) }
    let(:info_request) { InfoRequest.from_draft(draft) }

    it "builds an info_request from the draft" do
      expect(info_request.title).to eq draft.title
      expect(info_request.public_body).to eq draft.public_body
      expect(info_request.user).to eq draft.user
      expect(info_request).not_to be_persisted
    end

    it "builds an initial outgoing message" do
      expect(info_request.outgoing_messages.length).to eq 1
      outgoing_message = info_request.outgoing_messages.first
      expect(outgoing_message.body).to eq draft.body
      expect(outgoing_message.info_request).to eq info_request
      expect(outgoing_message.info_request).not_to be_persisted
    end

    context "when the draft has a duration" do
      it "builds an embargo" do
        expect(info_request.embargo).not_to be nil
        embargo = info_request.embargo
        expect(embargo.embargo_duration).to eq draft.embargo_duration
        expect(embargo.info_request).to eq info_request
        expect(embargo).not_to be_persisted
      end
    end

    context "when the draft doesnt have a duration" do
      let(:draft_with_no_duration) do
        FactoryGirl.create(:draft_with_no_duration)
      end

      let(:request_with_no_embargo) do
        InfoRequest.from_draft(draft_with_no_duration)
      end

      it "doesnt build an embargo" do
        expect(request_with_no_embargo.embargo).to be nil
      end
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

describe InfoRequest do

  describe '#state' do

    it 'returns a State::Calculator' do
      expect(InfoRequest.new.state).to be_a InfoRequest::State::Calculator
    end
  end

end
