# -*- encoding : utf-8 -*-
require 'spec_helper'

describe NotificationMailer do
  describe '#daily_summary' do
    let!(:user) { FactoryGirl.create(:user) }

    # Bodies
    let!(:public_body_1) do
      FactoryGirl.create(:public_body, name: "Ministry of fact keeping")
    end
    let!(:public_body_2) do
      FactoryGirl.create(:public_body, name: "Minor infractions quango")
    end

    # Requests
    let!(:new_response_request_1) do
      FactoryGirl.create(
        :info_request,
        title: "The cost of paperclips",
        public_body: public_body_1
      )
    end
    let(:embargo_expiring_request_1) do
      FactoryGirl.create(
        :embargo_expiring_request,
        title: "Missing staplers",
        public_body: public_body_1
      )
    end
    let(:embargo_expired_request_1) do
      FactoryGirl.create(
        :embargo_expired_request,
        title: "Misdelivered letters",
        public_body: public_body_1
      )
    end
    let(:overdue_request_1) do
      FactoryGirl.create(
        :overdue_request,
        title: "Late expenses claims",
        public_body: public_body_1
      )
    end
    let(:very_overdue_request_1) do
      FactoryGirl.create(
        :very_overdue_request,
        title: "Extremely late expenses claims",
        public_body: public_body_1
      )
    end
    let!(:new_response_and_embargo_expiring_request) do
      FactoryGirl.create(
        :info_request,
        title: "Thefts of stationary",
        public_body: public_body_2
      )
    end

    # Batch requests
    let!(:new_responses_batch_request) do
      batch = FactoryGirl.create(
        :info_request_batch,
        title: "Zero hours employees",
        user: user,
        public_bodies: [public_body_1, public_body_2]
      )
      batch.create_batch!
      batch
    end
    let!(:new_responses_batch_requests) do
      new_responses_batch_request.info_requests.order(:created_at)
    end
    let!(:embargo_expiring_batch_request) do
      batch = FactoryGirl.create(
        :info_request_batch,
        title: "Employees caught stealing stationary",
        user: user,
        public_bodies: [public_body_1, public_body_2]
      )
      batch.create_batch!
      batch
    end
    let!(:embargo_expiring_batch_requests) do
      embargo_expiring_batch_request.info_requests.order(:created_at)
    end
    let!(:embargo_expired_batch_request) do
      batch = FactoryGirl.create(
        :info_request_batch,
        title: "Employee of the month awards",
        user: user,
        public_bodies: [public_body_1, public_body_2]
      )
      batch.create_batch!
      batch
    end
    let!(:embargo_expired_batch_requests) do
      embargo_expired_batch_request.info_requests.order(:created_at)
    end
    let!(:overdue_batch_request) do
      batch = FactoryGirl.create(
        :info_request_batch,
        title: "Late FOI requests",
        user: user,
        public_bodies: [public_body_1, public_body_2]
      )
      batch.create_batch!
      batch
    end
    let!(:overdue_batch_requests) do
      overdue_batch_request.info_requests.order(:created_at)
    end
    let!(:very_overdue_batch_request) do
      batch = FactoryGirl.create(
        :info_request_batch,
        title: "Ignored FOI requests",
        user: user,
        public_bodies: [public_body_1, public_body_2]
      )
      batch.create_batch!
      batch
    end
    let!(:very_overdue_batch_requests) do
      overdue_batch_request.info_requests.order(:created_at)
    end

    # Incoming messages for new_response events
    # We need to force the ID numbers of these messages to be something known
    # so that we can predict the urls that will be included in the email
    let!(:incoming_1) do
      FactoryGirl.create(:incoming_message,
                         info_request: new_response_request_1,
                         id: 995)
    end
    let!(:incoming_2) do
      FactoryGirl.create(
        :incoming_message,
        info_request: new_response_and_embargo_expiring_request,
        id: 996)
    end
    let!(:incoming_3) do
      FactoryGirl.create(:incoming_message,
                         info_request: new_responses_batch_requests.first,
                         id: 997)
    end
    let!(:incoming_4) do
      FactoryGirl.create(:incoming_message,
                         info_request: new_responses_batch_requests.second,
                         id: 998)
    end

    # Notifications
    let!(:notification_1) do
      event = FactoryGirl.create(:response_event,
                                 incoming_message: incoming_1)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:notification_2) do
      event = FactoryGirl.create(:response_event,
                                 incoming_message: incoming_2)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:notification_3) do
      event = FactoryGirl.create(:embargo_expiring_event,
                                 info_request: embargo_expiring_request_1)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:notification_4) do
      event = FactoryGirl.create(
        :embargo_expiring_event,
        info_request: new_response_and_embargo_expiring_request)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:notification_5) do
      event = FactoryGirl.create(:overdue_event,
                                 info_request: overdue_request_1)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:notification_6) do
      event = FactoryGirl.create(:very_overdue_event,
                                 info_request: very_overdue_request_1)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:notification_7) do
      event = FactoryGirl.create(:expire_embargo_event,
                                 info_request: embargo_expired_request_1)
      FactoryGirl.create(:daily_notification, info_request_event: event,
                                              user: user)
    end
    let!(:new_response_batch_notifications) do
      notifications = []

      event_1 = FactoryGirl.create(:response_event,
                                   incoming_message: incoming_3)
      notifications << FactoryGirl.create(
        :daily_notification,
        info_request_event: event_1,
        user: user
      )

      event_2 = FactoryGirl.create(:response_event,
                                   incoming_message: incoming_4)
      notifications << FactoryGirl.create(
        :daily_notification,
        info_request_event: event_2,
        user: user
      )

      notifications
    end

    let!(:embargo_expiring_batch_notifications) do
      notifications = []

      event_1 = FactoryGirl.create(
        :embargo_expiring_event,
        info_request: embargo_expiring_batch_requests.first)
      notifications << FactoryGirl.create(
        :daily_notification,
        info_request_event: event_1,
        user: user
      )

      event_2 = FactoryGirl.create(
        :embargo_expiring_event,
        info_request: embargo_expiring_batch_requests.second)
      notifications << FactoryGirl.create(
        :daily_notification,
        info_request_event: event_2,
        user: user
      )

      notifications
    end

    let!(:embargo_expired_batch_notifications) do
      notifications = []

      event_1 = FactoryGirl.create(
        :expire_embargo_event,
        info_request: embargo_expired_batch_requests.first)
      notifications << FactoryGirl.create(
        :daily_notification,
        info_request_event: event_1,
        user: user
      )

      event_2 = FactoryGirl.create(
        :expire_embargo_event,
        info_request: embargo_expired_batch_requests.second)
      notifications << FactoryGirl.create(
        :daily_notification,
        info_request_event: event_2,
        user: user
      )

      notifications
    end

    let!(:overdue_batch_notifications) do
      notifications = []

      event_1 = FactoryGirl.create(
        :overdue_event,
        info_request: overdue_batch_requests.first
      )
      notifications << FactoryGirl.create(:daily_notification,
                                          info_request_event: event_1,
                                          user: user)

      event_2 = FactoryGirl.create(
        :overdue_event,
        info_request: overdue_batch_requests.second
      )
      notifications << FactoryGirl.create(:daily_notification,
                                          info_request_event: event_2,
                                          user: user)

      notifications
    end

    let!(:very_overdue_batch_notifications) do
      notifications = []

      event_1 = FactoryGirl.create(
        :very_overdue_event,
        info_request: very_overdue_batch_requests.first
      )
      notifications << FactoryGirl.create(:daily_notification,
                                          info_request_event: event_1,
                                          user: user)

      event_2 = FactoryGirl.create(
        :very_overdue_event,
        info_request: very_overdue_batch_requests.second
      )
      notifications << FactoryGirl.create(:daily_notification,
                                          info_request_event: event_2,
                                          user: user)

      notifications
    end

    let(:batch_notifications) do
      notifications = []
      notifications += new_response_batch_notifications
      notifications += embargo_expiring_batch_notifications
      notifications += embargo_expired_batch_notifications
      notifications += overdue_batch_notifications
      notifications += very_overdue_batch_notifications
    end

    let(:all_notifications) do
      notifications = [notification_1,
                       notification_2,
                       notification_3,
                       notification_4,
                       notification_5,
                       notification_6,
                       notification_7]
      notifications + batch_notifications
    end

    before do
      allow(PostRedirect).
        to receive(:generate_random_token).and_return('TOKEN')
    end

    it "send the message to the right user" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.to).to eq [user.email]
    end

    it "send the message from the right address" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it "sets the right subject line" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.subject).
        to eq ("Your daily request summary from Alaveteli Professional")
    end

    it "matches the expected message" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      file_name = file_fixture_name("notification_mailer/daily-summary.txt")
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
    end

    it "sets reply_to headers" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header["Reply-To"].value).to eq expected_reply_to
      expect(mail.header["Return-Path"].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it "sets auto-generated headers" do
      mail = NotificationMailer.daily_summary(user, all_notifications)
      expect(mail.header["Auto-Submitted"].value).to eq "auto-generated"
      expect(mail.header["X-Auto-Response-Suppress"].value).to eq "OOF"
    end
  end

  describe '#instant_notification' do
    let(:notification) { FactoryGirl.create(:instant_notification) }

    it 'returns a mail message to the user' do
      message = NotificationMailer.instant_notification(notification)
      expect(message.to).to eq([notification.user.email])
    end
  end

  describe '#response_notification' do
    let(:public_body) do
      FactoryGirl.create(:public_body, name: 'Test public body')
    end
    let(:info_request) do
      FactoryGirl.create(:info_request,
                         public_body: public_body,
                         title: "Here is a character that needs quoting …")
    end
    let(:incoming_message) do
      FactoryGirl.create(:incoming_message, info_request: info_request,
                                            id: 999)
    end
    let(:info_request_event) do
      FactoryGirl.create(:response_event, info_request: info_request,
                                          incoming_message: incoming_message)
    end
    let(:notification) do
      FactoryGirl.create(:notification,
                         info_request_event: info_request_event)
    end

    context "when the subject has characters which need quoting" do
      it 'should not error' do
        NotificationMailer.response_notification(notification)
      end
    end

    context "when the subject has characters which could be HTML escaped" do
      before do
        info_request.title = "Here's a request"
        info_request.save!
      end

      it 'should not create HTML entities' do
        mail = NotificationMailer.response_notification(notification)
        expected = "New response to your FOI request - Here's a request"
        expect(mail.subject).to eq expected
      end
    end

    it "sends the message to the right user" do
      mail = NotificationMailer.response_notification(notification)
      expect(mail.to).to eq [info_request.user.email]
    end

    it "sends the message from the right address" do
      mail = NotificationMailer.response_notification(notification)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it "sets reply_to headers" do
      mail = NotificationMailer.response_notification(notification)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header["Reply-To"].value).to eq expected_reply_to
      expect(mail.header["Return-Path"].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it "sets auto-generated headers" do
      mail = NotificationMailer.response_notification(notification)
      expect(mail.header["Auto-Submitted"].value).to eq "auto-generated"
      expect(mail.header["X-Auto-Response-Suppress"].value).to eq "OOF"
    end

    it 'should send the expected message' do
      mail = NotificationMailer.response_notification(notification)
      file_name = file_fixture_name("notification_mailer/new_response.txt")
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
    end

    context "when the user is a pro user" do
      let(:pro_user) { FactoryGirl.create(:pro_user) }

      before do
        info_request.user = pro_user
        info_request.save!
      end

      it 'should send the expected message' do
        mail = NotificationMailer.response_notification(notification)
        file_name = file_fixture_name(
          "notification_mailer/new_response_pro.txt"
        )
        expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
        expect(mail.body.encoded).to eq(expected_message)
      end
    end
  end

  describe 'embargo_expiring_notification' do
    let(:public_body) do
      FactoryGirl.create(:public_body, name: 'Test public body')
    end
    let(:info_request) do
      FactoryGirl.create(:embargo_expiring_request,
                         public_body: public_body,
                         title: "Here is a character that needs quoting …")
    end
    let(:info_request_event) do
      FactoryGirl.create(:embargo_expiring_event, info_request: info_request)
    end
    let(:notification) do
      FactoryGirl.create(:notification,
                         info_request_event: info_request_event)
    end

    context "when the subject has characters which need quoting" do
      it 'should not error' do
        NotificationMailer.embargo_expiring_notification(notification)
      end
    end

    context "when the subject has characters which could be HTML escaped" do
      before do
        info_request.title = "Here's a request"
        info_request.save!
        allow(AlaveteliConfiguration).
          to receive(:site_name).and_return("Something & something")
      end

      it 'should not create HTML entities' do
        mail = NotificationMailer.embargo_expiring_notification(notification)
        expected = "Your FOI request - Here's a request will be made " \
                   "public on Something & something this week"
        expect(mail.subject).to eq expected
      end
    end

    it "sends the message to the right user" do
      mail = NotificationMailer.embargo_expiring_notification(notification)
      expect(mail.to).to eq [info_request.user.email]
    end

    it "sends the message from the right address" do
      mail = NotificationMailer.embargo_expiring_notification(notification)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it "sets reply_to headers" do
      mail = NotificationMailer.embargo_expiring_notification(notification)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header["Reply-To"].value).to eq expected_reply_to
      expect(mail.header["Return-Path"].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it "sets auto-generated headers" do
      mail = NotificationMailer.embargo_expiring_notification(notification)
      expect(mail.header["Auto-Submitted"].value).to eq "auto-generated"
      expect(mail.header["X-Auto-Response-Suppress"].value).to eq "OOF"
    end

    it 'should send the expected message' do
      mail = NotificationMailer.embargo_expiring_notification(notification)
      file_name = file_fixture_name(
        "notification_mailer/embargo_expiring.txt")
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
    end
  end

  describe 'embargo_expired_notification' do
    let(:public_body) do
      FactoryGirl.create(:public_body, name: 'Test public body')
    end

    let(:info_request) do
      FactoryGirl.create(:embargo_expired_request,
                         public_body: public_body,
                         title: 'Here is a character that needs quoting …')
    end

    let(:info_request_event) { info_request.last_embargo_expire_event }

    let(:notification) do
      FactoryGirl.create(:notification,
                         info_request_event: info_request_event)
    end

    context 'when the subject has characters which need quoting' do

      it 'should not error' do
        NotificationMailer.embargo_expired_notification(notification)
      end

    end

    context 'when the subject has characters which could be HTML escaped' do
      before do
        info_request.title = "Here's a request"
        info_request.save!
        allow(AlaveteliConfiguration).
          to receive(:site_name).and_return('Something & something')
      end

      it 'should not create HTML entities' do
        mail = NotificationMailer.embargo_expired_notification(notification)
        expected = "Your FOI request - Here's a request has been made " \
                   "public on Something & something"
        expect(mail.subject).to eq expected
      end
    end

    it 'sends the message to the right user' do
      mail = NotificationMailer.embargo_expired_notification(notification)
      expect(mail.to).to eq [info_request.user.email]
    end

    it 'sends the message from the right address' do
      mail = NotificationMailer.embargo_expired_notification(notification)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it 'sets reply_to headers' do
      mail = NotificationMailer.embargo_expired_notification(notification)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header['Reply-To'].value).to eq expected_reply_to
      expect(mail.header['Return-Path'].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it 'sets auto-generated headers' do
      mail = NotificationMailer.embargo_expired_notification(notification)
      expect(mail.header['Auto-Submitted'].value).to eq 'auto-generated'
      expect(mail.header['X-Auto-Response-Suppress'].value).to eq 'OOF'
    end

    it 'should send the expected message' do
      mail = NotificationMailer.embargo_expired_notification(notification)
      file_name = file_fixture_name('notification_mailer/embargo_expired.txt')
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
    end

  end

  describe 'overdue_notification' do
    let(:public_body) do
      FactoryGirl.create(:public_body, name: 'Test public body')
    end
    let(:info_request) do
      FactoryGirl.create(:overdue_request,
                         public_body: public_body,
                         title: "Here is a character that needs quoting …")
    end
    let(:info_request_event) do
      FactoryGirl.create(:overdue_event, info_request: info_request)
    end
    let(:notification) do
      FactoryGirl.create(:notification,
                         info_request_event: info_request_event)
    end

    context "when the subject has characters which need quoting" do
      it 'should not error' do
        NotificationMailer.overdue_notification(notification)
      end
    end

    context "when the subject has characters which could be HTML escaped" do
      before do
        info_request.title = "Here's a request"
        info_request.save!
      end

      it 'should not create HTML entities' do
        mail = NotificationMailer.overdue_notification(notification)
        expected = "Delayed response to your FOI request - Here's a request"
        expect(mail.subject).to eq expected
      end
    end

    it "sends the message to the right user" do
      mail = NotificationMailer.overdue_notification(notification)
      expect(mail.to).to eq [info_request.user.email]
    end

    it "sends the message from the right address" do
      mail = NotificationMailer.overdue_notification(notification)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it "sets reply_to headers" do
      mail = NotificationMailer.overdue_notification(notification)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header["Reply-To"].value).to eq expected_reply_to
      expect(mail.header["Return-Path"].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it "sets auto-generated headers" do
      mail = NotificationMailer.overdue_notification(notification)
      expect(mail.header["Auto-Submitted"].value).to eq "auto-generated"
      expect(mail.header["X-Auto-Response-Suppress"].value).to eq "OOF"
    end

    it 'should send the expected message' do
      allow(PostRedirect).
        to receive(:generate_random_token).and_return('TOKEN')
      mail = NotificationMailer.overdue_notification(notification)
      file_name = file_fixture_name(
        "notification_mailer/overdue.txt")
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
    end
  end

  describe 'very_overdue_notification' do
    let(:public_body) do
      FactoryGirl.create(:public_body, name: 'Test public body')
    end
    let(:info_request) do
      FactoryGirl.create(:very_overdue_request,
                         public_body: public_body,
                         title: "Here is a character that needs quoting …")
    end
    let(:info_request_event) do
      FactoryGirl.create(:very_overdue_event, info_request: info_request)
    end
    let(:notification) do
      FactoryGirl.create(:notification,
                         info_request_event: info_request_event)
    end

    context "when the subject has characters which need quoting" do
      it 'should not error' do
        NotificationMailer.very_overdue_notification(notification)
      end
    end

    context "when the subject has characters which could be HTML escaped" do
      before do
        info_request.title = "Here's a request"
        info_request.save!
      end

      it 'should not create HTML entities' do
        mail = NotificationMailer.very_overdue_notification(notification)
        expected = "You're long overdue a response to your FOI request " \
                   "- Here's a request"
        expect(mail.subject).to eq expected
      end
    end

    it "sends the message to the right user" do
      mail = NotificationMailer.very_overdue_notification(notification)
      expect(mail.to).to eq [info_request.user.email]
    end

    it "sends the message from the right address" do
      mail = NotificationMailer.very_overdue_notification(notification)
      expect(mail.from).to eq ['postmaster@localhost']
    end

    it "sets reply_to headers" do
      mail = NotificationMailer.very_overdue_notification(notification)
      expected_reply_to = "#{AlaveteliConfiguration.contact_name} " \
                          "<#{AlaveteliConfiguration.contact_email}>"
      expect(mail.header["Reply-To"].value).to eq expected_reply_to
      expect(mail.header["Return-Path"].value).
        to eq 'do-not-reply-to-this-address@localhost'
    end

    it "sets auto-generated headers" do
      mail = NotificationMailer.very_overdue_notification(notification)
      expect(mail.header["Auto-Submitted"].value).to eq "auto-generated"
      expect(mail.header["X-Auto-Response-Suppress"].value).to eq "OOF"
    end

    it 'should send the expected message' do
      allow(PostRedirect).
        to receive(:generate_random_token).and_return('TOKEN')
      mail = NotificationMailer.very_overdue_notification(notification)
      file_name = file_fixture_name(
        "notification_mailer/very_overdue.txt")
      expected_message = File.open(file_name, 'r:utf-8') { |f| f.read }
      expect(mail.body.encoded).to eq(expected_message)
    end
  end

  describe ".send_daily_notifications" do
    let(:now) { Time.zone.now }
    let!(:notification_1) do
      FactoryGirl.create(:daily_notification, send_after: now)
    end
    let!(:notification_2) do
      FactoryGirl.create(:daily_notification, send_after: now)
    end

    # These next three notifications test that we don't pull out users we
    # shouldn't
    let!(:future_notification) do
      FactoryGirl.create(
        :daily_notification,
        send_after: Time.zone.now + 1.hour
      )
    end
    let!(:seen_notification) do
      FactoryGirl.create(:daily_notification, seen_at: Time.zone.now)
    end
    let!(:instant_notification) { FactoryGirl.create(:instant_notification) }

    let(:expected_notifications) { [notification_1, notification_2] }

    it "calls #daily_summary for each appropriate user" do
      expect(NotificationMailer).
        to receive(:daily_summary).
          with(notification_1.user, [notification_1]).
            and_call_original
      expect(NotificationMailer).
        to receive(:daily_summary).
          with(notification_2.user, [notification_2]).
            and_call_original
      NotificationMailer.send_daily_notifications
    end

    it "sends a mail for each expected user" do
      ActionMailer::Base.deliveries.clear

      NotificationMailer.send_daily_notifications

      expect(ActionMailer::Base.deliveries.size).to eq 2

      first_mail = ActionMailer::Base.deliveries.first
      expect(first_mail.to).to eq([notification_1.user.email])

      second_mail = ActionMailer::Base.deliveries.second
      expect(second_mail.to).to eq([notification_2.user.email])
    end

    context "when a user has instant notifications as well as daily ones" do
      let(:info_request) do
        FactoryGirl.create(:info_request, user: notification_1.user)
      end
      let(:incoming_message) do
        FactoryGirl.create(:incoming_message, info_request: info_request)
      end
      let(:info_request_event) do
        FactoryGirl.create(:response_event,
                           incoming_message: incoming_message,
                           info_request: info_request
        )
      end
      let(:instant_notification) do
        FactoryGirl.create(:instant_notification,
                           info_request_event: info_request_event)
      end

      it "doesn't include the instant notifications in their daily email" do
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_1.user, [notification_1]).
              and_call_original
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_2.user, [notification_2]).
              and_call_original

        NotificationMailer.send_daily_notifications
      end
    end

    context "when a user has seen notifications as well as unseen ones" do
      let(:info_request) do
        FactoryGirl.create(:info_request, user: notification_1.user)
      end
      let(:incoming_message) do
        FactoryGirl.create(:incoming_message, info_request: info_request)
      end
      let(:info_request_event) do
        FactoryGirl.create(:response_event,
                           incoming_message: incoming_message,
                           info_request: info_request
        )
      end
      let(:seen_notification) do
        FactoryGirl.create(:daily_notification,
                           info_request_event: info_request_event,
                           seen_at: Time.zone.now)
      end

      it "doesn't include the seen notifications" do
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_1.user, [notification_1]).
              and_call_original
        expect(NotificationMailer).
          to receive(:daily_summary).
            with(notification_2.user, [notification_2]).
              and_call_original

        NotificationMailer.send_daily_notifications
      end
    end

    it "updates all of the notifications' seen_at timestamps" do
      expected_notifications.each { |n| expect(n.seen_at).to be_nil }

      NotificationMailer.send_daily_notifications

      expected_notifications.each do |n|
        n.reload
        expect(n.seen_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    it "returns true when it has done something" do
      expect(NotificationMailer.send_daily_notifications).to be true
    end

    it "returns false when it hasn't done anything" do
      NotificationMailer.send_daily_notifications
      expect(NotificationMailer.send_daily_notifications).to be false
    end

    context "when some notifications have expired before being sent" do
      let(:embargo_expiring_request) do
        FactoryGirl.create(:embargo_expiring_request,
                           user: notification_1.user)
      end
      let(:embargo_expiring_event) do
        FactoryGirl.create(:embargo_expiring_event,
                           info_request: embargo_expiring_request)
      end
      let(:expired_notification_1) do
        FactoryGirl.create(:notification,
                           info_request_event: embargo_expiring_event)
      end

      let(:overdue_request) { FactoryGirl.create(:overdue_request) }
      let(:overdue_event) do
        FactoryGirl.create(:overdue_event, info_request: overdue_request)
      end
      let(:expired_notification_2) do
        FactoryGirl.create(:notification, info_request_event: overdue_event)
      end

      let(:very_overdue_request) { FactoryGirl.create(:very_overdue_request) }
      let(:very_overdue_event) do
        FactoryGirl.create(:very_overdue_event,
                           info_request: very_overdue_request)
      end
      let(:expired_notification_3) do
        FactoryGirl.create(:notification,
                           info_request_event: very_overdue_event)
      end

      it "doesn't send the expired notifications" do
        NotificationMailer.send_daily_notifications
        expect(expired_notification_1.reload.seen_at).to be nil
        expect(expired_notification_2.reload.seen_at).to be nil
        expect(expired_notification_3.reload.seen_at).to be nil
      end

      it "still marks the other notifications as having been seen" do
        expected_notifications.each { |n| expect(n.seen_at).to be_nil }

        NotificationMailer.send_daily_notifications

        expected_notifications.each do |n|
          n.reload
          expect(n.seen_at).to be_within(1.second).of(Time.zone.now)
        end
      end
    end
  end

  describe '.send_instant_notifications' do
    let!(:notification_1) { FactoryGirl.create(:instant_notification) }
    let!(:notification_2) { FactoryGirl.create(:instant_notification) }

    let!(:seen_notification) do
      FactoryGirl.create(:instant_notification, seen_at: Time.zone.now)
    end

    let!(:daily_notification) do
      FactoryGirl.create(:daily_notification)
    end

    it "calls .instant_notification for each notification" do
      expect(NotificationMailer).
        to receive(:instant_notification).twice.and_call_original
      NotificationMailer.send_instant_notifications
    end

    it "sends a mail for each unseen instant notification" do
      ActionMailer::Base.deliveries.clear

      NotificationMailer.send_instant_notifications

      expect(ActionMailer::Base.deliveries.size).to eq 2

      first_mail = ActionMailer::Base.deliveries.first
      expect(first_mail.to).to eq([notification_1.user.email])

      second_mail = ActionMailer::Base.deliveries.second
      expect(second_mail.to).to eq([notification_2.user.email])
    end

    it 'sets seen_at on the notifications' do
      expect(notification_1.seen_at).to be nil
      expect(notification_2.seen_at).to be nil

      NotificationMailer.send_instant_notifications

      notification_1.reload
      notification_2.reload

      expect(notification_1.seen_at).to be_within(1.second).of(Time.zone.now)
      expect(notification_2.seen_at).to be_within(1.second).of(Time.zone.now)
    end

    it "returns true when it has done something" do
      expect(NotificationMailer.send_instant_notifications).to be true
    end

    it "returns false when it hasn't done anything" do
      NotificationMailer.send_instant_notifications
      expect(NotificationMailer.send_instant_notifications).to be false
    end

    context "when some notifications have expired before being sent" do
      let(:embargo_expiring_request) do
        FactoryGirl.create(:embargo_expiring_request,
                           user: notification_1.user)
      end
      let(:embargo_expiring_event) do
        FactoryGirl.create(:embargo_expiring_event,
                           info_request: embargo_expiring_request)
      end
      let(:expired_notification) do
        FactoryGirl.create(:instant_notification,
                           info_request_event: embargo_expiring_event)
      end

      it "doesn't send the expired notifications" do
        NotificationMailer.send_daily_notifications
        expect(expired_notification.reload.seen_at).to be nil
      end
    end
  end

  describe ".send_notifications" do
    it "calls send_daily_notifications and send_instant_notifications" do
      expect(NotificationMailer).to receive(:send_daily_notifications)
      expect(NotificationMailer).to receive(:send_instant_notifications)
      NotificationMailer.send_notifications
    end

    it "returns true if either send_xxx method returns true" do
      allow(NotificationMailer).
        to receive(:send_daily_notifications).and_return(true)
      allow(NotificationMailer).
        to receive(:send_instant_notifications).and_return(true)
      expect(NotificationMailer.send_notifications).to eq true

      allow(NotificationMailer).
        to receive(:send_daily_notifications).and_return(true)
      allow(NotificationMailer).
        to receive(:send_instant_notifications).and_return(false)
      expect(NotificationMailer.send_notifications).to eq true

      allow(NotificationMailer).
        to receive(:send_daily_notifications).and_return(false)
      allow(NotificationMailer).
        to receive(:send_instant_notifications).and_return(true)
      expect(NotificationMailer.send_notifications).to eq true
    end

    it "returns false if both send_xxx method return false" do
      allow(NotificationMailer).
        to receive(:send_daily_notifications).and_return(false)
      allow(NotificationMailer).
        to receive(:send_instant_notifications).and_return(false)
      expect(NotificationMailer.send_notifications).to eq false
    end
  end
end
