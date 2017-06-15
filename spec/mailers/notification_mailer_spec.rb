# -*- encoding : utf-8 -*-
require 'spec_helper'

describe NotificationMailer do
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

  describe '#daily_summary' do
    let!(:user) { FactoryGirl.create(:user) }

    let!(:public_body_1) do
      FactoryGirl.create(:public_body, name: "Ministry of fact keeping")
    end
    let!(:public_body_2) do
      FactoryGirl.create(:public_body, name: "Minor infractions quango")
    end

    let!(:info_request_1) do
      FactoryGirl.create(
        :info_request,
        title: "The cost of paperclips",
        public_body: public_body_1
      )
    end
    let!(:info_request_2) do
      FactoryGirl.create(
        :info_request,
        title: "Thefts of stationary",
        public_body: public_body_2
      )
    end
    let!(:batch_request) do
      batch = FactoryGirl.create(
        :info_request_batch,
        title: "Zero hours employees",
        user: user,
        public_bodies: [public_body_1, public_body_2]
      )
      batch.create_batch!
      batch
    end
    let!(:batch_requests) { batch_request.info_requests.order(:created_at) }

    # We need to force the ID numbers of these messages to be something known
    # so that we can predict the urls that will be included in the email
    let!(:incoming_1) do
      FactoryGirl.create(:incoming_message, info_request: info_request_1,
                                            id: 995)
    end
    let!(:incoming_2) do
      FactoryGirl.create(:incoming_message, info_request: info_request_2,
                                            id: 996)
    end
    let!(:incoming_3) do
      FactoryGirl.create(:incoming_message,
                         info_request: batch_requests.first,
                         id: 997)
    end
    let!(:incoming_4) do
      FactoryGirl.create(:incoming_message,
                         info_request: batch_requests.second,
                         id: 998)
    end

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
    let!(:batch_notifications) do
      notifications = []

      event_1 = FactoryGirl.create(:response_event,
                                   incoming_message: incoming_3)
      notification_1 = FactoryGirl.create(
        :daily_notification,
        info_request_event: event_1,
        user: user
      )
      notifications << notification_1

      event_2 = FactoryGirl.create(:response_event,
                                   incoming_message: incoming_4)
      notification_2 = FactoryGirl.create(
        :daily_notification,
        info_request_event: event_2,
        user: user
      )
      notifications << notification_2

      notifications
    end

    let(:all_notifications) do
      notifications = [notification_1, notification_2]
      notifications + batch_notifications
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
end
