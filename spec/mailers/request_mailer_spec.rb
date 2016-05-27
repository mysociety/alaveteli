# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RequestMailer do

  describe "when receiving incoming mail" do

    before(:each) do
      load_raw_emails_data
      ActionMailer::Base.deliveries = []
    end

    it "should append it to the appropriate request" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.size).to eq(1) # in the fixture
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
      expect(ir.incoming_messages.size).to eq(2) # one more arrives
      expect(ir.info_request_events[-1].incoming_message_id).not_to be_nil

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ 'bob@localhost' ]) # to the user who sent fancy_dog_request
      deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the email is not to any information request" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
      receive_incoming_mail('incoming-request-plain.email', 'dummy@localhost')
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)
      last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).to eq("Could not identify the request from the email address")

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ AlaveteliConfiguration::contact_email ])
      deliveries.clear
    end

    it "puts messages with a malformed To: in the holding pen" do
      request = FactoryGirl.create(:info_request)
      receive_incoming_mail('incoming-request-plain.email', 'asdfg')
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)
    end

    it "should parse attachments from mails sent with apple mail" do
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
      receive_incoming_mail('apple-mail-with-attachments.email', 'dummy@localhost')
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)
      last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).to eq("Could not identify the request from the email address")

      im = IncomingMessage.last
      # Check that the attachments haven't been somehow loaded from a
      # previous test run
      expect(im.foi_attachments.size).to eq(0)

      # Trace where attachments first get loaded:
      # TODO: Ideally this should be 3, but some html parts from Apple Mail
      # are being treated like attachments
      im.extract_attachments!
      expect(im.foi_attachments.size).to eq(6)

      # Clean up
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ AlaveteliConfiguration::contact_email ])
      deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the from email is empty and only authorites can reply" do
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'authority_only'
      ir.handle_rejected_responses = 'holding_pen'
      ir.save!
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)
      last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).to match(/there is no "From" address/)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ AlaveteliConfiguration::contact_email ])
      deliveries.clear
    end

    it "should store mail in holding pen and send to admin when the from email is unknown and only authorites can reply" do
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'authority_only'
      ir.handle_rejected_responses = 'holding_pen'
      ir.save!
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "frob@nowhere.com")
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1)
      last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).to match(/Only the authority can reply/)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ AlaveteliConfiguration::contact_email ])
      deliveries.clear
    end

    it "should ignore mail sent to known spam addresses" do
      @spam_address = FactoryGirl.create(:spam_address)

      receive_incoming_mail('incoming-request-plain.email', @spam_address.email)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
      deliveries.clear
    end

    it "should return incoming mail to sender when a request is stopped fully for spam" do
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'bounce'
      ir.save!

      # test what happens if something arrives
      expect(ir.incoming_messages.size).to eq(1) # in the fixture
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
      expect(ir.incoming_messages.size).to eq(1) # nothing should arrive

      # should be a message back to sender
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ 'geraldinequango@localhost' ])
      # check attached bounce is good copy of incoming-request-plain.email
      expect(mail.multipart?).to eq(true)
      expect(mail.parts.size).to eq(2)
      message_part = mail.parts[0].to_s
      bounced_mail = MailHandler.mail_from_raw_email(mail.parts[1].body.to_s)
      expect(bounced_mail.to).to eq([ ir.incoming_email ])
      expect(bounced_mail.from).to eq([ 'geraldinequango@localhost' ])
      expect(bounced_mail.body.include?("That's so totally a rubbish question")).to be true
      expect(message_part.include?("marked to no longer receive responses")).to be true
      deliveries.clear
    end

    it "should return incoming mail to sender if not authority when a request is stopped for non-authority spam" do
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'authority_only'
      ir.handle_rejected_responses = 'bounce'
      ir.save!

      # Test what happens if something arrives from authority domain (@localhost)
      expect(ir.incoming_messages.size).to eq(1) # in the fixture
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "Geraldine <geraldinequango@localhost>")
      expect(ir.incoming_messages.size).to eq(2) # one more arrives

      # ... should get "responses arrived" message for original requester
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ 'bob@localhost' ]) # to the user who sent fancy_dog_request
      deliveries.clear

      # Test what happens if something arrives from another domain
      expect(ir.incoming_messages.size).to eq(2) # in fixture and above
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "dummy-address@dummy.localhost")
      expect(ir.incoming_messages.size).to eq(2) # nothing should arrive

      # ... should be a bounce message back to sender
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ 'dummy-address@dummy.localhost' ])
      deliveries.clear
    end

    it "discards rejected responses with a malformed From: when set to bounce" do
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'bounce'
      ir.save!
      expect(ir.incoming_messages.size).to eq(1)

      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email, "")
      expect(ir.incoming_messages.size).to eq(1)

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
      deliveries.clear
    end

    it "should send all new responses to holding pen if a request is marked to do so" do
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'holding_pen'
      ir.save!

      # test what happens if something arrives
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(1) # arrives in holding pen
      last_event = InfoRequest.holding_pen_request.incoming_messages[0].info_request.info_request_events.last
      expect(last_event.params[:rejected_reason]).to match(/allow new responses from nobody/)

      # should be a message to admin regarding holding pen
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.to).to eq([ AlaveteliConfiguration::contact_email ])
      deliveries.clear
    end

    it "should destroy the messages sent to a request if marked to do so" do
      ActionMailer::Base.deliveries.clear
      # mark request as anti-spam
      ir = info_requests(:fancy_dog_request)
      ir.allow_new_responses_from = 'nobody'
      ir.handle_rejected_responses = 'blackhole'
      ir.save!

      # test what happens if something arrives - should be nothing
      ir = info_requests(:fancy_dog_request)
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)
      receive_incoming_mail('incoming-request-plain.email', ir.incoming_email)
      expect(ir.incoming_messages.size).to eq(1)
      expect(InfoRequest.holding_pen_request.incoming_messages.size).to eq(0)

      # should be no messages to anyone
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end


    it "should not mutilate long URLs when trying to word wrap them" do
      long_url = 'http://www.this.is.quite.a.long.url.flourish.org/there.is.no.way.it.is.short.whatsoever'
      body = "This is a message with quite a long URL in it. It also has a paragraph, being this one that has quite a lot of text in it to. Enough to test the wrapping of itself.

#{long_url}

  And a paragraph afterwards."
      wrapped = MySociety::Format.wrap_email_body_by_paragraphs(body)
      expect(wrapped).to include(long_url)
    end

  end


  describe "when sending reminders to requesters to classify a response to their request" do

    let(:old_request) do
      InfoRequest.destroy_all
      FactoryGirl.create(:old_unclassified_request)
    end

    def send_alerts
      RequestMailer.alert_new_response_reminders_internal(7, 'new_response_reminder_1')
    end

    def sent_alert_params(request, type)
      {:info_request_id => request.id,
       :user_id => request.user.id,
       :info_request_event_id => request.get_last_public_response_event_id,
       :alert_type => type}
    end

    it 'should raise an error if a request does not have a last response event id' do
      old_request.info_request_events.clear
      old_request.save!
      expected_message = "internal error, no last response while making alert " \
                         "new response reminder, request id #{old_request.id}"
      expect{ send_alerts }.to raise_error(expected_message)
    end

    context 'if an alert matching the attributes of the reminder to be sent has already been sent' do

      it 'should not send the reminder' do
        params = sent_alert_params(old_request, 'new_response_reminder_1')
        UserInfoRequestSentAlert.create!(params)
        expect(RequestMailer).not_to receive(:new_response_reminder_alert)
        send_alerts
      end

    end

    context 'if no alert matching the attributes of the reminder to be sent has already been sent' do

      before do
        allow(UserInfoRequestSentAlert).to receive(:find).and_return(nil)
      end

      it 'should store the information that the reminder has been sent' do
        old_request
        send_alerts
        expect(UserInfoRequestSentAlert.where(sent_alert_params(old_request, 'new_response_reminder_1'))).not_to be_empty
      end

      it 'should send the reminder' do
        send_alerts
        deliveries = ActionMailer::Base.deliveries
        mail = deliveries[0]
        expect(mail.body).to match(/Letting everyone know whether you got the information/)
      end


    end

  end

  describe "when sending mail when someone has updated an old unclassified request" do

    let(:user) do
      FactoryGirl.create(:user, :name => "test name", :email => "email@localhost")
    end

    let(:public_body) { FactoryGirl.create(:public_body, :name => "Test public body") }

    let(:info_request) do
      FactoryGirl.create(:info_request, :user => user,
                                        :title => "Test request",
                                        :public_body => public_body,
                                        :url_title => "test_request")
    end

    let(:mail) { RequestMailer.old_unclassified_updated(info_request) }

    before do
      allow(info_request).to receive(:display_status).and_return("refused.")
    end

    it 'should have the subject "Someone has updated the status of your request"' do
      expect(mail.subject).to eq('Someone has updated the status of your request')
    end

    it 'should tell them what status was picked' do
      expect(mail.body).to match(/"refused."/)
    end

    it 'should contain the request path' do
      expect(mail.body).to match(/request\/test_request/)
    end

  end

  describe "when generating a fake response for an upload" do

    before do
      @foi_officer = mock_model(User, :name_and_email => "FOI officer's name and email")
      @request_user = mock_model(User)
      @public_body = mock_model(PublicBody, :name => 'Test public body')
      @info_request = mock_model(InfoRequest, :user => @request_user,
                                 :email_subject_followup => 'Re: Freedom of Information - Test request',
                                 :incoming_name_and_email => 'Someone <someone@example.org>')
    end

    it 'should should generate a "fake response" email with a reasonable subject line' do
      fake_email = RequestMailer.fake_response(@info_request,
                                               @foi_officer,
                                               "The body of the email...",
                                               "blah.txt",
                                               "The content of blah.txt")
      expect(fake_email.subject).to eq("Re: Freedom of Information - Test request")
    end

  end

  describe "when sending a new response email" do

    let(:user) do
      FactoryGirl.create(:user, :name => "test name",
                                :email => "email@localhost")
    end

    let(:public_body) do
      FactoryGirl.create(:public_body, :name => "Test public body")
    end

    let(:info_request) do
      FactoryGirl.create(:info_request,
                         :user => user,
                         :title => "Here is a character that needs quoting …",
                         :public_body => public_body,
                         :described_state => 'rejected',
                         :url_title => "test_request")
    end

    let(:incoming_message) do
      FactoryGirl.create(:incoming_message, :info_request => info_request)
    end

    it 'should not error when sending mails requests with characters requiring quoting in the subject' do
      mail = RequestMailer.new_response(info_request, incoming_message)
    end

    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.new_response(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:incoming_message))
      expect(mail.subject).to eq "New response to your FOI request - Here's a request"
    end

  end

  describe "sending unclassified new response reminder alerts" do

    before(:each) do
      load_raw_emails_data
    end

    it "sends an alert" do
      RequestMailer.alert_new_response_reminders

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(3) # sufficiently late it sends reminders too
      mail = deliveries[0]
      expect(mail.body).to match(/To let everyone know/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      post_redirect = PostRedirect.find_by_email_token(mail_token)
      expect(post_redirect.uri).
        to match(show_request_path(info_requests(:fancy_dog_request).url_title))

      # check anchor tag goes to last new response
      expect(post_redirect.uri.split("#").last).
        to eq("describe_state_form_1")
    end

  end

  describe "requires_admin" do

    let(:user) do
      FactoryGirl.create(:user, :name => "Bruce Jones",
                                :email => "bruce@example.com")
    end

    let(:info_request) do
      FactoryGirl.create(:info_request, :user => user,
                                        :title => "It's a Test request",
                                        :url_title => "test_request",
                                        :id => 123)
    end

    before do
      info_request.described_state = 'error_message'
      info_request.save
    end

    it 'body should contain the full admin URL' do
      mail = RequestMailer.requires_admin(info_request).deliver
      expect(mail.body).to include('http://test.host/en/admin/requests/123')
    end

    it "body should contain the message from the user" do
      mail = RequestMailer.requires_admin(info_request, nil, "Something has gone wrong").deliver
      expect(mail.body).to include 'Something has gone wrong'
    end

    it 'should not create HTML entities in the subject line' do
      expect(RequestMailer.requires_admin(info_request).subject).
        to eq "FOI response requires admin (error_message) - It's a Test request"
    end

    it 'sets the "Reply-To" header header to the sender' do
      expect(RequestMailer.requires_admin(info_request).header['Reply-To'].to_s).
        to eq('Bruce Jones <bruce@example.com>')
    end

    it 'sets the "Return-Path" header to the blackhole address' do
      expect(RequestMailer.requires_admin(info_request).header['Return-Path'].to_s).
        to eq('do-not-reply-to-this-address@localhost')
    end

  end

  describe "sending overdue request alerts" do

    let(:request_date) { Time.zone.parse('2010-12-12') }
    let(:overdue_date) { request_date - 31.days }
    let(:very_overdue_date) { request_date - 61.days }

    before(:each) do
      @kitten_request = FactoryGirl.create(:info_request,
                                           :title => "Do you really own a kitten?")
      @kitten_request.outgoing_messages[0].last_sent_at = overdue_date
      @kitten_request.outgoing_messages[0].save!
    end

    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.overdue_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:user))
      expect(mail.subject).to eq "Delayed response to your FOI request - Here's a request"
    end

    it "sends an overdue alert mail to request creators" do
      allow(Time).to receive(:now).and_return(request_date)
      RequestMailer.alert_overdue_requests

      kitten_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
      expect(kitten_mails.size).to eq(1)
      mail = kitten_mails[0]

      expect(mail.body).to match(/promptly, as normally/)
      expect(mail.to_addrs.first.to_s).to eq(@kitten_request.user.email)

      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      post_redirect = PostRedirect.find_by_email_token(mail_token)
      expect(post_redirect.uri).
        to match(new_request_followup_path(@kitten_request.id))
    end

    it "does not send the alert if the user is banned but records it as sent" do
      user = @kitten_request.user
      user.ban_text = 'Banned'
      user.save!
      expect(UserInfoRequestSentAlert.find_all_by_user_id(user.id).count).to eq(0)
      RequestMailer.alert_overdue_requests

      deliveries = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
      expect(deliveries.size).to eq(0)
      expect(UserInfoRequestSentAlert.find_all_by_user_id(user.id).count).to be > 0
    end

    it "does not resend alerts to people who've already received them" do
      RequestMailer.alert_overdue_requests
      kitten_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
      expect(kitten_mails.size).to eq(1)
      RequestMailer.alert_overdue_requests
      kitten_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
      expect(kitten_mails.size).to eq(1)
    end

    it "sends alerts for requests where the last event forming the initial
          request is a followup being sent following a request for clarification" do
      RequestMailer.alert_overdue_requests
      kitten_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
      expect(kitten_mails.size).to eq(1)

      # Request is waiting clarification
      @kitten_request.set_described_state('waiting_clarification')

      # Followup message is sent
      outgoing_message = OutgoingMessage.new(:status => 'ready',
                                             :message_type => 'followup',
                                             :info_request_id => @kitten_request.id,
                                             :body => 'Some text',
                                             :what_doing => 'normal_sort')

      outgoing_message.sendable?
      mail_message = OutgoingMailer.followup(
        outgoing_message.info_request,
        outgoing_message,
        outgoing_message.incoming_message_followup
      ).deliver
      outgoing_message.record_email_delivery(mail_message.to_addrs.join(', '), mail_message.message_id)

      outgoing_message.save!

      kitten_request = InfoRequest.find(@kitten_request.id)

      # Last event forming the request is now the followup
      expect(kitten_request.last_event_forming_initial_request.event_type).to eq('followup_sent')

      # This isn't overdue, so no email
      RequestMailer.alert_overdue_requests
      kitten_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
      expect(kitten_mails.size).to eq(1)

      # Make the followup older
      outgoing_message.last_sent_at = very_overdue_date
      outgoing_message.save!

      # Now it should be alerted on
      RequestMailer.alert_overdue_requests
      kitten_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
      expect(kitten_mails.size).to eq(2)
    end

    context "very overdue alerts" do

      it 'should not create HTML entities in the subject line' do
        mail = RequestMailer.very_overdue_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:user))
        expect(mail.subject).to eq "You're long overdue a response to your FOI request - Here's a request"
      end

      it "sends a very overdue alert mail to creators of very overdue requests" do
        @kitten_request.outgoing_messages[0].last_sent_at = very_overdue_date
        @kitten_request.outgoing_messages[0].save!

        RequestMailer.alert_overdue_requests

        kitten_mails = ActionMailer::Base.deliveries.select{|x| x.body =~ /kitten/}
        expect(kitten_mails.size).to eq(1)
        mail = kitten_mails[0]

        expect(mail.body).to match(/required by law/)
        expect(mail.to_addrs.first.to_s).to eq(@kitten_request.user.email)

        mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
        mail_url = $1
        mail_token = $2

        post_redirect = PostRedirect.find_by_email_token(mail_token)
        expect(post_redirect.uri).
          to match(new_request_followup_path(@kitten_request.id))
      end

    end

  end

  describe "not_clarified_alert" do

    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.not_clarified_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:incoming_message))
      expect(mail.subject).to eq "Clarify your FOI request - Here's a request"
    end

  end

  describe "comment_on_alert" do

    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.comment_on_alert(FactoryGirl.create(:info_request, :title => "Here's a request"), FactoryGirl.create(:comment))
      expect(mail.subject).to eq "Somebody added a note to your FOI request - Here's a request"
    end

  end

  describe "comment_on_alert_plural" do

    it 'should not create HTML entities in the subject line' do
      mail = RequestMailer.comment_on_alert_plural(FactoryGirl.create(:info_request, :title => "Here's a request"), 2, FactoryGirl.create(:comment))
      expect(mail.subject).to eq "Some notes have been added to your FOI request - Here's a request"
    end

  end

  describe "clarification required alerts" do

    before(:each) do
      load_raw_emails_data
    end

    it "should send an alert" do
      ir = info_requests(:fancy_dog_request)
      ir.set_described_state('waiting_clarification')
      # this is pretty horrid, but will do :) need to make it waiting
      # clarification more than 3 days ago for the alerts to go out.
      ActiveRecord::Base.connection.update "update info_requests set updated_at = '" + (Time.zone.now - 5.days).strftime("%Y-%m-%d %H:%M:%S") + "' where id = " + ir.id.to_s
      ir.reload

      RequestMailer.alert_not_clarified_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/asked you to explain/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*\/c\/(.*))/
      mail_url = $1
      mail_token = $2

      post_redirect = PostRedirect.find_by_email_token(mail_token)
      expect(post_redirect.uri).
        to match(new_request_incoming_followup_path(:request_id => ir.id,
                                    :incoming_message_id => ir.incoming_messages.last.id))
    end

    it "should not send an alert to banned users" do
      ir = info_requests(:fancy_dog_request)
      ir.set_described_state('waiting_clarification')

      ir.user.ban_text = 'Banned'
      ir.user.save!

      # this is pretty horrid, but will do :) need to make it waiting
      # clarification more than 3 days ago for the alerts to go out.
      ActiveRecord::Base.connection.update "update info_requests set updated_at = '" + (Time.zone.now - 5.days).strftime("%Y-%m-%d %H:%M:%S") + "' where id = " + ir.id.to_s
      ir.reload

      RequestMailer.alert_not_clarified_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

  end

  describe "comment alerts" do
    before(:each) do
      load_raw_emails_data
    end

    it "should send an alert (once and once only)" do
      # delete fixture comment and make new one, so is in last month (as
      # alerts are only for comments in last month, see
      # RequestMailer.alert_comment_on_request)
      existing_comment = info_requests(:fancy_dog_request).comments[0]
      existing_comment.info_request_events[0].destroy
      existing_comment.destroy
      new_comment = info_requests(:fancy_dog_request).add_comment('I really love making annotations.', users(:silly_name_user))

      # send comment alert
      RequestMailer.alert_comment_on_request
      deliveries = ActionMailer::Base.deliveries
      mail = deliveries[0]
      expect(mail.body).to match(/has annotated your/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*)/
      mail_url = $1
      expect(mail_url).to match("/request/why_do_you_have_such_a_fancy_dog#comment-#{new_comment.id}")

      # check if we send again, no more go out
      deliveries.clear
      RequestMailer.alert_comment_on_request
      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it "should not send an alert when you comment on your own request" do
      # delete fixture comment and make new one, so is in last month (as
      # alerts are only for comments in last month, see
      # RequestMailer.alert_comment_on_request)
      existing_comment = info_requests(:fancy_dog_request).comments[0]
      existing_comment.info_request_events[0].destroy
      existing_comment.destroy
      new_comment = info_requests(:fancy_dog_request).add_comment('I also love making annotations.', users(:bob_smith_user))

      # try to send comment alert
      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it 'should not send an alert for a comment on an external request' do
      external_request = info_requests(:external_request)
      external_request.add_comment("This external request is interesting", users(:silly_name_user))
      # try to send comment alert
      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(0)
    end

    it "should send an alert when there are two new comments" do
      # add two comments - the second one sould be ignored, as is by the user who made the request.
      # the new comment here, will cause the one in the fixture to be picked up as a new comment by alert_comment_on_request also.
      new_comment = info_requests(:fancy_dog_request).add_comment('Not as daft as this one', users(:silly_name_user))
      new_comment = info_requests(:fancy_dog_request).add_comment('Or this one!!!', users(:bob_smith_user))

      RequestMailer.alert_comment_on_request

      deliveries = ActionMailer::Base.deliveries
      expect(deliveries.size).to eq(1)
      mail = deliveries[0]
      expect(mail.body).to match(/There are 2 new annotations/)
      expect(mail.to_addrs.first.to_s).to eq(info_requests(:fancy_dog_request).user.email)
      mail.body.to_s =~ /(http:\/\/.*)/
      mail_url = $1
      expect(mail_url).to match("/request/why_do_you_have_such_a_fancy_dog#comment-#{comments(:silly_comment).id}")
    end

  end

end
